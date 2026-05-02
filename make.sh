#!/bin/bash 

set -euxo pipefail

BASEDIR="$( cd "$( dirname "$(realpath $BASH_SOURCE)" )" && pwd )"
OUTDIR="${BASEDIR}/out"

list_hats() {
    find "$BASEDIR" \
        -maxdepth 1 -mindepth 1 \
        -type d -not -name .github  -not -name _common -not -name .git -not -name out \
        -printf '%f\n'
}

render_snippets() {
    local DIRECTORY="$1"

    while IFS= read -r snippet; do
        echo "# ${snippet#"$BASEDIR/"}"
        cat "${snippet}"
        echo
    done < <(find "${DIRECTORY}" -maxdepth 1 -name '*.snippet.Containerfile' | sort)
}

make_containerfile() {
    local HAT="$1"
    local TARGET_FILE="$OUTDIR/$HAT.Containerfile"

    cat <<EOF > "$TARGET_FILE"
ARG BASE_IMAGE
FROM \$BASE_IMAGE

$(render_snippets "${BASEDIR}/_common/")

$(render_snippets "${BASEDIR}/$HAT/")

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
