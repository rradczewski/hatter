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
    fd-find \
    ripgrep \
    just \
    gparted \
    smartmontools \
    qemu-guest-agent

RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
        @xfce-desktop-environment \
        gnome-initial-setup \
        --exclude=lightdm \
        --exclude=lightdm-gtk

RUN \
    systemctl enable gdm && \
    systemctl set-default graphical.target