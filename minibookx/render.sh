#!/bin/env bash

set -euxo pipefail

BASE_DIR="$( cd "$( dirname "$(realpath "$BASH_SOURCE")" )/../" && pwd )"
source "$BASE_DIR/_tooling/render_snippets.sh"
source "$BASE_DIR/_tooling/build_image_version.sh"

BASE_IMAGE=quay.io/fedora/fedora-silverblue:43@sha256:4802436b652a30a945fbee6cb2db02d63cdbdc54cfd9ca8ce183c72261a81591
VERSION=$(build_image_version "$BASE_IMAGE")

render_hat() {
    cat <<EOF
FROM $BASE_IMAGE

$(render_snippets "${BASE_DIR}/_common/")
$(render_snippets "${BASE_DIR}/minibookx/")

ARG VERSION="${VERSION}"
ARG HAT="vanilla"
$(render_snippets "${BASE_DIR}/_common_meta/")

RUN ostree container commit
EOF
}