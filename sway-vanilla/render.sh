#!/bin/env bash

set -euxo pipefail

BASE_DIR="$( cd "$( dirname "$(realpath "$BASH_SOURCE")" )/../" && pwd )"
source "$BASE_DIR/_tooling/render_snippets.sh"
source "$BASE_DIR/_tooling/build_image_version.sh"

BASE_IMAGE=ghcr.io/rradczewski/hatter/base/fedora/fedora-sway-atomic:44-x86_64-now@sha256:d94df7694c4e73e173c91c6740ca2ad3e2020680d11d129a49548c9231dfa2bc
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