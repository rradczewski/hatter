#!/bin/bash 

set -euxo pipefail

BASEDIR="$( cd "$( dirname "$(realpath $BASH_SOURCE)" )" && pwd )"
OUTDIR="${BASEDIR}/out"

list_hats() {
    find "$BASEDIR" \
        -maxdepth 1 -mindepth 1 \
        -type d -not -name _common -not -name .git -not -name out \
        -printf '%f\n'
}

make_containerfile() {
    local HAT="$1"
    local TARGET_FILE="$OUTDIR/$HAT.Containerfile"

    cat <<EOF > "$TARGET_FILE"
FROM quay.io/fedora/fedora-silverblue:43

$(find "${BASEDIR}/_common/" -name *.snippet.Containerfile -printf '# '_common/'%f\n' -exec cat {} \; -printf '\n')

$(find "${BASEDIR}/$HAT/" -name *.snippet.Containerfile -printf '# '$HAT/'%f\n' -exec cat {} \; -printf '\n')

RUN ostree container commit
EOF
}


run() {
    mkdir -p "$OUTDIR" || true
    local HATS=$(list_hats)
    for hat in $HATS
    do
        make_containerfile "$hat"
    done
}


run