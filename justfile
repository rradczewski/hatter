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
    just generate_temporary_signing_keys
    export KERNEL_SIGNING_CERTIFICATE_KEY=$(cat ./tmp/kernel_signing_key/kernel_signing_certificate_key.key)
    export KERNEL_SIGNING_CERTIFICATE_PEM=$(cat ./tmp/kernel_signing_key/kernel_signing_certificate_key.pem)
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
  DIGEST=$(cat "out/{{ hat }}.iid")
  buildah push "$DIGEST" "docker://$IMAGE_TAG"
  buildah push "$DIGEST" "docker://$IMAGE:edge"

sign hat:
  #!/bin/env bash
  set -euxo pipefail

  source "out/{{ hat }}.meta"
  DIGEST=$(cat "out/{{ hat }}.iid")
  cosign sign --yes ${IMAGE}@${DIGEST}