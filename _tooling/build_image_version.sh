#!/bin/env bash

set -euo pipefail

build_image_version() {
    local BASE_IMAGE="$1"

    local BUILD_REF
    local SOURCE_REF

    local BASE_IMAGE_WITHOUT_TAG=${BASE_IMAGE//:*@/@}
    local BASE_VERSION
    BASE_VERSION=$(skopeo inspect \
        docker://${BASE_IMAGE_WITHOUT_TAG/} \
            --format "{{ index .Labels \"org.opencontainers.image.version\" }}")

    
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
