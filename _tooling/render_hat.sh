#!/bin/env bash

set -euo pipefail

BASE_DIR="$( cd "$( dirname "$(realpath "$BASH_SOURCE")" )/../" && pwd )"
OUT_DIR="${BASE_DIR}/out"

run() {
    local HAT_DIR="$1"
    local HAT_NAME=$(basename "$HAT_DIR")
    mkdir -p "$OUT_DIR" || true

    (
        source "$HAT_DIR/render.sh"
        render_hat | tee "$OUT_DIR/$HAT_NAME.Containerfile"
        cat <<EOF | tee "$OUT_DIR/$HAT_NAME.meta"
VERSION="${VERSION}"
HAT="${HAT_NAME}"
IMAGE="ghcr.io/rradczewski/hatter/$HAT_NAME"
IMAGE_TAG="ghcr.io/rradczewski/hatter/$HAT_NAME:$VERSION"
EOF
    )
}


run "$1"