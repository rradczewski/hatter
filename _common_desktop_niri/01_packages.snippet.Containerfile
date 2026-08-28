RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
        avahi \
        brightnessctl \
        flatpak \
        gcr \
        gnome-disk-utility \
        gnome-keyring \
        gnome-keyring-pam \
        gnome-system-monitor \
        mesa-dri-drivers \
        mesa-vulkan-drivers \
        nautilus \
        niri \
        niri-settings \
        noctalia \
        plymouth-system-theme \
        power-profiles-daemon \
        ptyxis \
        seahorse \
        system-config-printer \
        tuigreet \
        upower \
        wl-clipboard \
        wl-mirror \
        xclip \
        xdg-desktop-portal-gnome \
        xdg-desktop-portal-gtk \
        xdg-desktop-portal-wlr

RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
        --setopt=install_weak_deps=False \
        kdeconnectd
