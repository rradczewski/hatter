#!/bin/bash

# Adapted from:
# https://github.com/omid-1985/nextcloud-nautilus-integration
# Installer for "Nextcloud Integration" Nautilus Script
# Coded by: Omid Khalili inspired by initial work of Philipp Fruck (https://gist.github.com/p-fruck/6ec354da8fb348c19cca013c6c64df76)
# License: GNU General Public License (GPL) version 3+
# Description: Implement Nextcloud Nautilus Integration for Nextcloud Flatpak package
# Requires: bash, nautilus, nautilus-python, nextcloud-desktop-client via flatpak 

set -uexo pipefail

TMP_DIR=/tmp/nextcloud_desktop/working_directory

mkdir -p "$TMP_DIR" || true

rpm --install --verbose --hash --nodeps $(dnf repoquery --location nextcloud-client-nautilus | head -n1)

NEXTCLOUD_CLIENT_RPM=$(dnf repoquery nextcloud-client --latest-limit=1 --queryformat "%{name}-%{evr}.%{arch}")

dnf download --destdir "$TMP_DIR" "$NEXTCLOUD_CLIENT_RPM"

rpm2cpio "${TMP_DIR}/${NEXTCLOUD_CLIENT_RPM}.rpm" \
    | cpio -imvd \
        -D / \
        './usr/share/icons/hicolor/*'

gtk-update-icon-cache -f /usr/share/icons/hicolor/
