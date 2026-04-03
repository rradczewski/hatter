# Version without video codecs, install flathub version and ffmpeg-full instead
RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf remove -y firefox firefox-langpacks

RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
    podman-compose \
    btrfs-assistant \
    snapper \
    pv \
    mbuffer \
    lm_sensors \
    powertop \
    tmux \
    vim \
    gparted \
    smartmontools \
    gnome-extensions-app \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-no-overview \
    gnome-shell-extension-gsconnect \
    blueman-nautilus \
    nautilus-gsconnect \
    gnome-tweaks
