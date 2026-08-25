#!/usr/bin/env bash
# Live-preview an installed Plymouth theme without touching GRUB, kargs, or the
# initramfs. Temporarily points plymouthd's config at the given theme, shows the
# splash on the current VT for a few seconds, then restores whatever theme was
# configured before. Run as root, from a free virtual console (not the one your
# Wayland session owns) - e.g. switch to it with Ctrl+Alt+F3 first.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root (sudo $0 ...)." >&2
    exit 1
fi

THEME="${1:-}"
SECONDS_TO_SHOW="${2:-8}"

if [ -z "$THEME" ]; then
    echo "Usage: $0 <theme-name> [seconds]" >&2
    echo >&2
    echo "Available themes:" >&2
    plymouth-set-default-theme --list >&2
    exit 1
fi

PREVIOUS_THEME="$(plymouth-set-default-theme)"
cleanup() {
    plymouth --quit >/dev/null 2>&1 || true
    plymouth-set-default-theme "$PREVIOUS_THEME" >/dev/null
}
trap cleanup EXIT

plymouth-set-default-theme "$THEME"
plymouthd --mode=boot --debug --tty="$(tty)"
plymouth --show-splash
sleep "$SECONDS_TO_SHOW"
