#!/bin/env bash

set -euxo pipefail

BASE_DIR="$( cd "$( dirname "$(realpath "$BASH_SOURCE")" )/../" && pwd )"
source "$BASE_DIR/_tooling/render_snippets.sh"
source "$BASE_DIR/_tooling/build_image_version.sh"

BASE_IMAGE=ghcr.io/rradczewski/hatter/base/fedora/fedora-silverblue:44-x86_64-now@sha256:c4b01f3840ff99524a28b8d65fe7bfb8ed31bed432d80f3940924b93e0212371
VERSION=$(build_image_version "$BASE_IMAGE")

render_hat() {
    cat <<EOF
FROM $BASE_IMAGE

$(render_snippets "${BASE_DIR}/_common/")
$(render_snippets "${BASE_DIR}/_common_flatpak_setup/")
$(render_snippets "${BASE_DIR}/_common_desktop/")
$(render_snippets "${BASE_DIR}/ibp14/" "tuxedo-rpms.snippet.Containerfile")

ARG VERSION="${VERSION}"
ARG HAT="$HAT_NAME"
$(render_snippets "${BASE_DIR}/_common_meta/")

RUN ostree container commit
EOF
}
