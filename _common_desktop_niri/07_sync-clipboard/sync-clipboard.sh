#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/sync-clipboard"
mkdir -p "$STATE_DIR"
WL_HASH_FILE="$STATE_DIR/wl.sha256"
X11_HASH_FILE="$STATE_DIR/x11.sha256"
touch "$WL_HASH_FILE" "$X11_HASH_FILE"

hash_of() { sha256sum | cut -d' ' -f1; }

check_and_sync() {
    local quiet="$1"
    local wl_content wl_hash x11_content x11_hash last_wl last_x11

    wl_content="$(wl-paste --no-newline 2>/dev/null)" || wl_content=""
    wl_hash="$(printf '%s' "$wl_content" | hash_of)"
    x11_content="$(xclip -selection clipboard -o 2>/dev/null)" || x11_content=""
    x11_hash="$(printf '%s' "$x11_content" | hash_of)"

    last_wl="$(<"$WL_HASH_FILE")"
    last_x11="$(<"$X11_HASH_FILE")"

    if [[ -n "$x11_content" && "$x11_hash" != "$last_x11" && "$x11_hash" != "$wl_hash" ]]; then
        printf '%s' "$x11_content" | wl-copy
        echo "$x11_hash" > "$WL_HASH_FILE"
        echo "$x11_hash" > "$X11_HASH_FILE"
        echo "Received data from X11, copied to Wayland"
    elif [[ -n "$wl_content" && "$wl_hash" != "$last_wl" && "$wl_hash" != "$x11_hash" ]]; then
        printf '%s' "$wl_content" | xclip -selection clipboard
        echo "$wl_hash" > "$X11_HASH_FILE"
        echo "$wl_hash" > "$WL_HASH_FILE"
        echo "Received data from Wayland, copied to X11"
    else
        echo "$x11_hash" > "$X11_HASH_FILE"
        echo "$wl_hash" > "$WL_HASH_FILE"
        [[ "$quiet" == "true" ]] || echo "No clipboard changes to sync"
    fi
}

usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [--daemon]

  (no args)  Run one check-and-sync pass in the foreground, then exit
  --daemon   Run continuously, checking every 0.5s (used by the systemd service)
EOF
    exit 1
}

case "${1:-}" in
    --daemon)
        while true; do
            check_and_sync true
            sleep 0.5
        done
        ;;
    "")
        check_and_sync false
        ;;
    *)
        usage
        ;;
esac
