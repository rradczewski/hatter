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
    pv \
    mbuffer \
    lm_sensors \
    powertop \
    htop \
    tmux \
    vim \
    fd-find \
    ripgrep \
    just \
    smartmontools \
    @virtualization
