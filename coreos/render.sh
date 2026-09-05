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

BASE_IMAGE=ghcr.io/rradczewski/hatter/base/fedora/fedora-coreos:next-now@sha256:4b0e18d8c1e57b26ef17bb24c2d1ca9ba1935d3117f1b60521a80e1df3f82cd5
VERSION=$(build_coreos_image_version "$BASE_IMAGE")

render_hat() {
    cat <<EOF
FROM $BASE_IMAGE

$(render_snippets "${BASE_DIR}/_common/")
$(render_snippets "${BASE_DIR}/${HAT_NAME}/")

ARG VERSION="${VERSION}"
ARG HAT="$HAT_NAME"
$(render_snippets "${BASE_DIR}/_common_meta/")

RUN ostree container commit
EOF
}