# Re-applies the same XDG_DATA_DIRS priority as the systemd
# user-environment-generator override (10_xdg-data-dirs-override.generator):
# per-user dirs (under $HOME) > /usr/share/xdg-overrides > everything else.
#
# niri-session unconditionally runs `systemctl --user import-environment`
# (https://github.com/niri-wm/niri/pull/3572), which re-imports this shell's
# environment into the systemd --user manager and clobbers whatever the
# generator computed there. Named to sort after /etc/profile.d/flatpak.sh so
# it also sees (and can reposition) the dirs that adds.

OVERRIDE_DIR="/usr/share/xdg-overrides"

value="$XDG_DATA_DIRS"
if [ -z "$value" ]; then
    value="/usr/local/share/:/usr/share/"
fi

old_ifs=$IFS
IFS=:
set -f
set -- $value
set +f
IFS=$old_ifs

user_dirs=""
global_dirs=""
for entry in "$@"; do
    [ -z "$entry" ] && continue
    [ "$entry" = "$OVERRIDE_DIR" ] && continue
    if [ -n "$HOME" ]; then
        case "$entry" in
            "$HOME"|"$HOME"/*)
                user_dirs="${user_dirs:+$user_dirs:}$entry"
                continue
                ;;
        esac
    fi
    global_dirs="${global_dirs:+$global_dirs:}$entry"
done

result="$OVERRIDE_DIR"
[ -n "$user_dirs" ] && result="$user_dirs:$result"
[ -n "$global_dirs" ] && result="$result:$global_dirs"

export XDG_DATA_DIRS="$result"
