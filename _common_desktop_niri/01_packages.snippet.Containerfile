RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
        avahi \
        brightnessctl \
        flatpak \
        gtkgreet \
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
        ptyxis \
        seahorse \
        system-config-printer \
        wl-clipboard \
        xclip \
        xdg-desktop-portal-gtk \
        xdg-desktop-portal-wlr

RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
        --setopt=install_weak_deps=False \
        kdeconnectd