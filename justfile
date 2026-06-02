BASE_IMAGE_PREFIX := "ghcr.io/rradczewski/hatter/base/"

rotate_base_image image:
  #!/bin/env bash
  set -euxo pipefail

  SOURCE_IMAGE="{{ image }}"
  IMAGE_PATH=${SOURCE_IMAGE#*/}

  TARGET_IMAGE_NEXT="{{ BASE_IMAGE_PREFIX }}${IMAGE_PATH}-next"
  TARGET_IMAGE_NOW="{{ BASE_IMAGE_PREFIX }}${IMAGE_PATH}-now"

  NEW_IMAGE=$(skopeo inspect --format "{{ "{{.Name}}@{{.Digest}}" }}" "docker://$SOURCE_IMAGE")
  
  set +e
  if ! skopeo inspect "docker://${TARGET_IMAGE_NEXT}" 2>&1 > /dev/null; then
    echo "No next image, copying new next to current next"
    skopeo copy --all "docker://$NEW_IMAGE" "docker://${TARGET_IMAGE_NEXT}"
  fi
  set -e

  skopeo copy "docker://$TARGET_IMAGE_NEXT" "docker://${TARGET_IMAGE_NOW}"
  skopeo copy "docker://$NEW_IMAGE" "docker://${TARGET_IMAGE_NEXT}"


generate_temporary_signing_keys:
  #!/bin/env bash
  mkdir -p ./tmp/kernel_signing_key/ || true
  openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 > ./tmp/kernel_signing_key/kernel_signing_certificate_key.key
  openssl req -x509 -key ./tmp/kernel_signing_key/kernel_signing_certificate_key.key -subj /CN=github.com/CN=rradczewski/CN=hatter/CN=CI_THROAWAY_KEY_DO_NOT_TRUST > ./tmp/kernel_signing_key/kernel_signing_certificate_key.pem

list-as-json cmd:
  just "{{cmd}}" |  jq -R '.' | jq -sc '.'

list-changed-hats:
  #!/usr/bin/env bash
  set -euxo pipefail

  changed_folders=$(
    git diff --name-only origin/main...HEAD \
      | cut -d'/' -f1 \
      | sort -u
  )

  subtasks=$(just list-hats | sort -u)

  comm -12 <(echo "$changed_folders") <(echo "$subtasks")

list-hats:
  find . -maxdepth 1 -mindepth 1 -type d \
    -not -name '.*' \
    -not -name '_*' \
    -not -name tmp \
    -not -name out \
    -printf '%f\n'

render hat:
  ./_tooling/render_hat.sh "{{ hat }}"

build hat: (render hat)
  #!/bin/env bash
  set -eo pipefail

  if [ -z "$KERNEL_SIGNING_CERTIFICATE_KEY" ] || [ -z "$KERNEL_SIGNING_CERTIFICATE_PEM" ]; then
    echo "Generating temporary signing keys"
    just generate_temporary_signing_keys
    export KERNEL_SIGNING_CERTIFICATE_KEY=$(cat ./tmp/kernel_signing_key/kernel_signing_certificate_key.key)
    export KERNEL_SIGNING_CERTIFICATE_PEM=$(cat ./tmp/kernel_signing_key/kernel_signing_certificate_key.pem)
  else 
    echo "Using existing signing keys"

    PUBKEY_FROM_REPO=$(cat "./signing_key.pub" | openssl x509 -noout -pubkey)
    PUBKEY_FROM_PRIVATE_KEY=$(echo "$KERNEL_SIGNING_CERTIFICATE_KEY" | openssl pkey -pubout)
    PUBKEY_FROM_CERTIFICATE=$(echo "$KERNEL_SIGNING_CERTIFICATE_PEM" | openssl x509 -noout -pubkey)
    if [ "$PUBKEY_FROM_REPO" != "$PUBKEY_FROM_CERTIFICATE" ] || [ "$PUBKEY_FROM_CERTIFICATE" != "$PUBKEY_FROM_PRIVATE_KEY" ] || [ -z "$PUBKEY_FROM_CERTIFICATE" ] || [ -z "$PUBKEY_FROM_PRIVATE_KEY" ];
    then
      echo "Pubkeys don't match"
      echo "Repo: $PUBKEY_FROM_REPO"
      echo "Private Key: $PUBKEY_FROM_PRIVATE_KEY"
      echo "Pub: $PUBKEY_FROM_CERTIFICATE"
      exit 1
    fi
  fi

  set -euxo pipefail

  source "out/{{ hat }}.meta"

  BUILDAH_OPT=""
  set +u
  if [ "$GITHUB_REF" == "refs/heads/main" ]; then
    BUILDAH_OPT="--cache-to=ghcr.io/rradczewski/hatter-cache"
  fi
  set -u

  IIDFILE="out//{{ hat }}.iid"
  buildah \
    build \
    --cache-ttl=168h \
    --cache-from=ghcr.io/rradczewski/hatter-cache \
    $BUILDAH_OPT \
    --iidfile "$IIDFILE" \
    --layers \
    --format oci \
    --secret id=KERNEL_SIGNING_CERTIFICATE_KEY,env=KERNEL_SIGNING_CERTIFICATE_KEY \
    --secret id=KERNEL_SIGNING_CERTIFICATE_PEM,env=KERNEL_SIGNING_CERTIFICATE_PEM \
    -t "$IMAGE_TAG" \
    -f "out/{{ hat }}.Containerfile" \
    .
  
  cat "$IIDFILE"

push hat:
  #!/bin/env bash
  set -euxo pipefail

  source "out/{{ hat }}.meta"
  IMAGE_ID=$(cat "out/{{ hat }}.iid")
  DIGESTFILE="out//{{ hat }}.digest"
  buildah push --digestfile "$DIGESTFILE" "$IMAGE_ID" "docker://$IMAGE_TAG"
  buildah push "$IMAGE_ID" "docker://$IMAGE:edge"

sign hat:
  #!/bin/env bash
  set -euxo pipefail

  source "out/{{ hat }}.meta"
  DIGEST=$(cat "out/{{ hat }}.digest")
  cosign sign --verbose --yes ${IMAGE}@${DIGEST}

iso hat:
  #!/bin/env bash
  set -euxo pipefail

  source "out/{{ hat }}.meta"
  IMAGE_ID=$(cat "out/{{ hat }}.iid")
  DIGEST=$(podman inspect "${IMAGE_ID#sha256:}" --format {{ "{{.Digest}}" }})

  OUT_DIR="./out/{{ hat }}.iso/"
  mkdir "$OUT_DIR" || true

  sudo skopeo copy \
    'containers-storage:[overlay@'$HOME'/.local/share/containers/storage+/run/user/'$(id -u)'/containers]'${IMAGE}@${DIGEST} \
    'containers-storage:[overlay@/var/lib/containers/storage]'${IMAGE_TAG}
  
  sudo podman run \
    --rm \
    -it \
    --privileged \
    --security-opt label=type:unconfined_t \
    -v "$OUT_DIR":/output \
    --volume "./_tooling/anaconda-iso.toml:/config.toml:z" \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest@sha256:754fc17718f977313885379e2c779066aba7d15af88fe04b486baec74759f574 \
    --rootfs btrfs \
    --verbose \
    --type anaconda-iso \
    ${IMAGE}@${DIGEST}
  sudo chown $(id -u) -vR "$OUT_DIR"

vm hat:
  #!/bin/env bash
  set -euxo pipefail

  source "out/{{ hat }}.meta"
  IMAGE_ID=$(cat "out/{{ hat }}.iid")
  DIGEST=$(podman inspect "${IMAGE_ID#sha256:}" --format {{ "{{.Digest}}" }})

  OUT_DIR="./out/{{ hat }}.vm/"
  mkdir "$OUT_DIR" || true

  sudo skopeo copy \
    'containers-storage:[overlay@'$HOME'/.local/share/containers/storage+/run/user/'$(id -u)'/containers]'${IMAGE}@${DIGEST} \
    'containers-storage:[overlay@/var/lib/containers/storage]'${IMAGE_TAG}
  
  sudo podman run \
    --rm \
    -it \
    --volume "./{{ hat }}/config.toml:/config.toml:z" \
    --privileged \
    --security-opt label=type:unconfined_t \
    -v "$OUT_DIR":/output \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest@sha256:754fc17718f977313885379e2c779066aba7d15af88fe04b486baec74759f574 \
    --rootfs btrfs \
    --verbose \
    --type qcow2 \
    ${IMAGE}@${DIGEST}
  sudo chown $(id -u) -vR "$OUT_DIR"

update-digest hat:
  #!/bin/env bash
  set -euxo pipefail

  CURRENT_REF=$(grep -oP '^BASE_IMAGE=\K(.+)' "{{ hat }}/render.sh")
  CURRENT_REF_WITHOUT_DIGEST=${CURRENT_REF//@*/}

  NEW_DIGEST=$(skopeo inspect "docker://${CURRENT_REF_WITHOUT_DIGEST}" --format "{{ "{{ .Digest }}" }}")

  UPDATED_REF=${CURRENT_REF_WITHOUT_DIGEST}@${NEW_DIGEST}

  sed -i 's|^BASE_IMAGE=.*$|BASE_IMAGE='${UPDATED_REF}'|' "{{ hat }}/render.sh"
