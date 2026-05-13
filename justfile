generate_temporary_signing_keys:
  #!/bin/env bash
  mkdir -p ./tmp/kernel_signing_key/ || true
  openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 > ./tmp/kernel_signing_key/kernel_signing_certificate_key.key
  openssl req -x509 -key ./tmp/kernel_signing_key/kernel_signing_certificate_key.key -subj /CN=github.com/CN=rradczewski/CN=hatter/CN=CI_THROAWAY_KEY_DO_NOT_TRUST > ./tmp/kernel_signing_key/kernel_signing_certificate_key.pem


render hat:
  ./_tooling/render_hat.sh "{{ hat }}"

build hat: (render hat)
  #!/bin/env bash
  set -eo pipefail

  if [ -z "$KERNEL_SIGNING_CERTIFICATE_KEY" ] || [ -z "$KERNEL_SIGNING_CERTIFICATE_PEM" ]; then
    just generate_temporary_signing_keys
    export KERNEL_SIGNING_CERTIFICATE_KEY=$(cat ./tmp/kernel_signing_key/kernel_signing_certificate_key.key)
    export KERNEL_SIGNING_CERTIFICATE_PEM=$(cat ./tmp/kernel_signing_key/kernel_signing_certificate_key.pem)
  fi

  set -euxo pipefail

  source "out/{{ hat }}.meta"

  BUILDAH_OPT=""
  if [ "$GITHUB_REF" == "refs/heads/main" ]; then
    BUILDAH_OPT="--cache-from=ghcr.io/rradczewski/hatter-cache --cache-to=ghcr.io/rradczewski/hatter-cache --push"
  fi

  IIDFILE="out//{{ hat }}.iid"
  buildah \
    build \
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
  DIGEST=$(cat "out/{{ hat }}.iid")
  buildah push "$DIGEST" "docker://$IMAGE_TAG"

sign hat:
  #!/bin/env bash
  set -euxo pipefail

  source "out/{{ hat }}.meta"
  DIGEST=$(cat "out/{{ hat }}.iid")
  cosign sign --yes ${IMAGE}@${DIGEST}