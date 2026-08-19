# Version without video codecs, install flathub version and ffmpeg-full instead
RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf remove -y firefox firefox-langpacks

# Install lxqt-polkit unless the base image already provides a polkit agent
RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    rpm -q --whatprovides PolicyKit-authentication-agent || dnf install -y lxqt-policykit

# See comment above, otherwise gparted pulls in gnome
RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
    btrfs-assistant \
    snapper \
    libinput-utils \
    google-cousine-fonts \
    gparted
