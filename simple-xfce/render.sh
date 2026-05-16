#!/bin/env bash

set -euxo pipefail

BASE_DIR="$( cd "$( dirname "$(realpath "$BASH_SOURCE")" )/../" && pwd )"
source "$BASE_DIR/_tooling/render_snippets.sh"
source "$BASE_DIR/_tooling/build_image_version.sh"

BASE_IMAGE=quay.io/fedora/fedora-bootc:44-x86_64@sha256:3635a8badef63c941b2e7120f8e17bc2c3ea4ac49b4edbd91b096aef26b54b4a
VERSION=$(build_image_version "$BASE_IMAGE")

render_hat() {
    cat <<EOF
FROM $BASE_IMAGE

$(render_snippets "${BASE_DIR}/_common/")

ARG VERSION="${VERSION}"
ARG HAT="simple-xfce"
$(render_snippets "${BASE_DIR}/_common_meta/")

RUN ostree container commit
EOF
}