#!/bin/env bash

set -euo pipefail

render_snippets() {
    local DIRECTORY="$1"

    while IFS= read -r snippet; do
        echo "# ${snippet#"$BASE_DIR/"}"
        cat "${snippet}"
        echo
    done < <(find "${DIRECTORY}" -maxdepth 1 -name '*.snippet.Containerfile' | sort)
}
