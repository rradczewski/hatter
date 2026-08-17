RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
    niri \
    niri-settings \
    noctalia \
    @lxqt-desktop \
    wl-clipboard \
    xclip \
    swaylock