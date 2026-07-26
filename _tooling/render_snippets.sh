#!/bin/env bash

set -euo pipefail

render_snippets() {
    local DIRECTORY="$1"
    shift

    local find_args=()
    for skip in "$@"; do
        find_args+=(! -name "$skip")
    done

    while IFS= read -r snippet; do
        echo "# ${snippet#"$BASE_DIR/"}"
        cat "${snippet}"
        echo
    done < <(find "${DIRECTORY}" -maxdepth 1 -name '*.snippet.Containerfile' "${find_args[@]}" | sort)
}