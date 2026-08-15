#!/bin/env bash

set -euxo pipefail

BASE_DIR="$( cd "$( dirname "$(realpath "$BASH_SOURCE")" )/../" && pwd )"
source "$BASE_DIR/_tooling/render_snippets.sh"
source "$BASE_DIR/_tooling/build_image_version.sh"

BASE_IMAGE=ghcr.io/rradczewski/hatter/base/fedora-ostree-desktops/cosmic-atomic:44-now@sha256:f7a74a9244841482930828437e821ad5472d35384022febce5acd2f222b879d7 
VERSION=$(build_image_version "$BASE_IMAGE")

render_hat() {
    cat <<EOF
FROM $BASE_IMAGE

$(render_snippets "${BASE_DIR}/_common/")
$(render_snippets "${BASE_DIR}/_common_flatpak_setup/")
$(render_snippets "${BASE_DIR}/_common_desktop/")
$(render_snippets "${BASE_DIR}/${HAT_NAME}/")

ARG VERSION="${VERSION}"
ARG HAT="$HAT_NAME"
$(render_snippets "${BASE_DIR}/_common_meta/")

RUN ostree container commit
EOF
}