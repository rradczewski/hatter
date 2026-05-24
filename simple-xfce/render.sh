#!/bin/env bash

set -euxo pipefail

BASE_DIR="$( cd "$( dirname "$(realpath "$BASH_SOURCE")" )/../" && pwd )"
source "$BASE_DIR/_tooling/render_snippets.sh"
source "$BASE_DIR/_tooling/build_image_version.sh"

BASE_IMAGE=quay.io/fedora/fedora-bootc:44-x86_64@sha256:3942ba68298f381f5f7bf9dd78c53171ad702f030cc78c53d11759ca6488dce0
VERSION=$(build_image_version "$BASE_IMAGE")

render_hat() {
    cat <<EOF
FROM $BASE_IMAGE

$(render_snippets "${BASE_DIR}/_common/")
$(render_snippets "${BASE_DIR}/_common_flatpak_setup/")

ARG VERSION="${VERSION}"
ARG HAT="simple-xfce"
$(render_snippets "${BASE_DIR}/_common_meta/")

RUN ostree container commit
EOF
}