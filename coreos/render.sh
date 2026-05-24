#!/bin/env bash

set -euxo pipefail

build_coreos_image_version() {
    local BASE_IMAGE="$1"

    local BUILD_REF
    local SOURCE_REF

    local BASE_IMAGE_WITHOUT_TAG=${BASE_IMAGE//:*@/@}
    local BASE_VERSION
    BASE_VERSION=$(skopeo inspect \
        docker://${BASE_IMAGE_WITHOUT_TAG/} \
            --format "{{ index .Labels \"org.opencontainers.image.version\" }}")

    local prefix="${BASE_VERSION%%.*}"
    local rest="${BASE_VERSION#*.}"
    BASE_VERSION="$prefix.${rest//.}"

    set +u
    if [ ! -z "$GITHUB_SHA" ]; then
        BUILD_REF="$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT"
        SOURCE_REF="g$GITHUB_SHA"
    else
        BUILD_REF="dev"
        SOURCE_REF="g$(git rev-parse --short HEAD)"
    fi
    set -u

    trunkver generate \
        --build-ref="$BUILD_REF" \
        --source-ref="$SOURCE_REF" \
        --prerelease "$BASE_VERSION"
}


BASE_DIR="$( cd "$( dirname "$(realpath "$BASH_SOURCE")" )/../" && pwd )"
source "$BASE_DIR/_tooling/render_snippets.sh"
source "$BASE_DIR/_tooling/build_image_version.sh"

BASE_IMAGE=quay.io/fedora/fedora-coreos:next@sha256:108a3cb096d519663dd446b3b57ed83b6bba8d19715e4d525297ec202310b95e
VERSION=$(build_coreos_image_version "$BASE_IMAGE")

render_hat() {
    cat <<EOF
FROM $BASE_IMAGE

$(render_snippets "${BASE_DIR}/_common/")

ARG VERSION="${VERSION}"
ARG HAT="coreos"
$(render_snippets "${BASE_DIR}/_common_meta/")

RUN ostree container commit
EOF
}