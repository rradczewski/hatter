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
    google-cousine-fonts \
    lm_sensors \
    powertop \
    tmux \
    vim \
    fd-find \
    ripgrep \
    just \
    gparted \
    smartmontools \
    @virtualization
