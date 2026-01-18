# Version without video codecs, install flathub version and ffmpeg-full instead
RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf remove firefox firefox-langpacks

RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install \
    podman-compose \
    btrfs-assistant \
    snapper \
    lm_sensors \
    powertop \
    tmux \
    vim \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-no-overview \
    gnome-shell-extension-gsconnect \
    nautilus-gsconnect \
    gnome-tweaks