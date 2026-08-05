RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
    gnome-extensions-app \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-no-overview \
    gnome-shell-extension-gsconnect \
    blueman-nautilus \
    nautilus-gsconnect \
    gnome-tweaks
