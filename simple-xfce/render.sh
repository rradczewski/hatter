#!/bin/env bash

set -euxo pipefail

BASE_DIR="$( cd "$( dirname "$(realpath "$BASH_SOURCE")" )/../" && pwd )"
source "$BASE_DIR/_tooling/render_snippets.sh"
source "$BASE_DIR/_tooling/build_image_version.sh"

BASE_IMAGE=ghcr.io/rradczewski/hatter/base/fedora/fedora-bootc:44-x86_64-now@sha256:34bd300a1f7a74d09151ba8a0077ca0ff27cf152b96e71e02b753d583e2c526e
VERSION=$(build_image_version "$BASE_IMAGE")

render_hat() {
    cat <<EOF
FROM $BASE_IMAGE

$(render_snippets "${BASE_DIR}/_common/")
$(render_snippets "${BASE_DIR}/_common_flatpak_setup/")
$(render_snippets "${BASE_DIR}/simple-xfce/")

ARG VERSION="${VERSION}"
ARG HAT="simple-xfce"
$(render_snippets "${BASE_DIR}/_common_meta/")

RUN ostree container commit
EOF
}