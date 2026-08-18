RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
        niri \
        niri-settings \
        noctalia \
        wl-clipboard \
        xclip \
        swaylock \
        kdeconnectd \
        brightnessctl \
        nautilus \
        ptyxis \
        avahi \
        seahorse \
        gnome-keyring \
        xdg-desktop-portal-gnome