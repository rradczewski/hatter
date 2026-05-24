RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
        dbus-tools dbus-daemon

ADD ./_common_flatpak_setup/01_flatpak-setup/flathub.flatpakrepo \
    /usr/share/flatpak/remotes.d/

ADD ./_common_flatpak_setup/01_flatpak-setup/flatpak-install@.service \
    ./_common_flatpak_setup/01_flatpak-setup/flatpak-permissions@.service \
    /etc/systemd/system/

COPY --chmod=0755 ./_common_flatpak_setup/01_flatpak-setup/flatpak-install-generator /usr/lib/systemd/system-generators/flatpak-install-generator
COPY --chmod=0755 ./_common_flatpak_setup/01_flatpak-setup/flatpak-install-run       /usr/libexec/flatpak-install-run
