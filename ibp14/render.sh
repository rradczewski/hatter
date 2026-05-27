#!/bin/env bash

set -euxo pipefail

BASE_DIR="$( cd "$( dirname "$(realpath "$BASH_SOURCE")" )/../" && pwd )"
source "$BASE_DIR/_tooling/render_snippets.sh"
source "$BASE_DIR/_tooling/build_image_version.sh"

BASE_IMAGE=quay.io/fedora/fedora-silverblue:44-x86_64@sha256:62baf2f8f3efc903cd21765e882575f39740b36ce7e1f32368ed412f21c3f768
VERSION=$(build_image_version "$BASE_IMAGE")

render_hat() {
    cat <<EOF
FROM $BASE_IMAGE

$(render_snippets "${BASE_DIR}/_common/")
$(render_snippets "${BASE_DIR}/_common_flatpak_setup/")
$(render_snippets "${BASE_DIR}/_common_desktop/")
$(render_snippets "${BASE_DIR}/ibp14/")

ARG VERSION="${VERSION}"
ARG HAT="vanilla"
$(render_snippets "${BASE_DIR}/_common_meta/")

RUN ostree container commit
EOF
}
