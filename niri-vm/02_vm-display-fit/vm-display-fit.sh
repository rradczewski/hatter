#!/usr/bin/env bash
set -euo pipefail

# The host's viewer (virt-manager/virt-viewer) requests a guest resolution
# in GTK device pixels: on a fractionally scaled host that is 2x the logical
# window size. Divide it back down and render at guest scale 1.
FACTOR="${VM_FIT_FACTOR:-2}"
MAX_MODE="${VM_FIT_MAX:-2752x1152}"
REFRESH="${VM_FIT_REFRESH:-60}"
OUTPUT_PATTERN="${VM_FIT_OUTPUTS:-^Virtual-}"

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/vm-display-fit"
mkdir -p "$STATE_DIR"

fit() {
    local quiet="$1"
    local name pref_w pref_h target cur last_file

    while IFS=$'\t' read -r name pref_w pref_h target cur; do
        last_file="$STATE_DIR/$name"
        # If the viewer shrank its window to the mode we just set, don't follow
        # it down - that would spiral to ever smaller resolutions.
        if [[ "${pref_w}x${pref_h}" == "$(cat "$last_file" 2>/dev/null)" && "${pref_w}x${pref_h}" != "$target" ]]; then
            [[ "$quiet" == "true" ]] || echo "$name: preferred ${pref_w}x${pref_h} is our own mode, ignoring"
            continue
        fi
        if [[ "$cur" == "$target" ]]; then
            [[ "$quiet" == "true" ]] || echo "$name: already at $target"
            continue
        fi
        echo "$name: preferred ${pref_w}x${pref_h} -> ${target}@${REFRESH} (scale 1)"
        niri msg output "$name" custom-mode "${target}@${REFRESH}"
        niri msg output "$name" scale 1
        echo "$target" > "$last_file"
    done < <(
        niri msg --json outputs | jq -r \
            --arg pattern "$OUTPUT_PATTERN" \
            --argjson factor "$FACTOR" \
            --argjson max_w "${MAX_MODE%x*}" \
            --argjson max_h "${MAX_MODE#*x}" '
            .[]
            | select(.name | test($pattern))
            | (.modes | map(select(.is_preferred)) | first) as $pref
            | select($pref != null)
            # Width rounded down to a multiple of 8, which every driver accepts
            | ([($pref.width / $factor | floor), $max_w] | min | . - (. % 8)) as $w
            | ([($pref.height / $factor | floor), $max_h] | min) as $h
            | [.name, $pref.width, $pref.height, "\($w)x\($h)",
               (if .logical and .logical.scale == 1 then "\(.logical.width)x\(.logical.height)" else "-" end)]
            | @tsv'
    )
}

usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [--daemon]

  (no args)  Fit virtual outputs once, then exit
  --daemon   Fit once, then again on every DRM hotplug (used by the systemd service)

Environment (the service reads these from /etc/vm-display-fit.conf):
  VM_FIT_FACTOR   divisor for the size the viewer requests (default 2)
  VM_FIT_MAX      maximum mode, WxH (default 2752x1152)
  VM_FIT_REFRESH  refresh rate in Hz (default 60)
  VM_FIT_OUTPUTS  regex of output names to manage (default ^Virtual-)
EOF
    exit 1
}

case "${1:-}" in
    --daemon)
        fit true
        while read -r _; do
            # A window drag emits a burst of events; act once it settles
            while read -r -t 0.5 _; do :; done
            fit true || echo "fit failed, will retry on next event" >&2
        done < <(udevadm monitor --udev --subsystem-match=drm | grep --line-buffered ' change ')
        ;;
    "")
        fit false
        ;;
    *)
        usage
        ;;
esac
