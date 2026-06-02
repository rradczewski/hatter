RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
    @xfce-desktop-environment \
    podman-compose \
    btrfs-assistant \
    snapper \
    pv \
    mbuffer \
    lm_sensors \
    powertop \
    tmux \
    vim \
    fd-find \
    ripgrep \
    just \
    gparted \
    smartmontools \
    qemu-guest-agent

RUN \
    systemctl set-default graphical.target