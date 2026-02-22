#!/bin/bash

# Adapted from:
# https://github.com/omid-1985/nextcloud-nautilus-integration
# Installer for "Nextcloud Integration" Nautilus Script
# Coded by: Omid Khalili inspired by initial work of Philipp Fruck (https://gist.github.com/p-fruck/6ec354da8fb348c19cca013c6c64df76)
# License: GNU General Public License (GPL) version 3+
# Description: Implement Nextcloud Nautilus Integration for Nextcloud Flatpak package
# Requires: bash, nautilus, nautilus-python, nextcloud-desktop-client via flatpak 

set -uexo pipefail

COMMIT_REF=5651436252ce6a34aebf892b663295d9593b50b1

mkdir /tmp/nextcloud_desktop 
curl -L -o /tmp/nextcloud_desktop/nextcloud_desktop.tar.gz https://github.com/nextcloud/desktop/archive/${COMMIT_REF}.tar.gz
tar -xvz \
  --strip-components=1 \
  -C /tmp/nextcloud_desktop \
  -f /tmp/nextcloud_desktop/nextcloud_desktop.tar.gz 

mkdir -p /usr/share/nautilus-python/extensions
cp /tmp/nextcloud_desktop/shell_integration/nautilus/syncstate.py /usr/share/nautilus-python/extensions

shopt -p
shopt -s nullglob globstar
for size in 128x128 16x16 256x256 32x32 48x48 64x64 72x72
do
  target=/usr/share/icons/hicolor/${size}/apps
  mkdir -p "${target}"
  for icon in /tmp/nextcloud_desktop/shell_integration/icons/${size}/*
  do
    basename=$(basename "${icon}")
    cp "${icon}" "${target}/${basename/oC/Nextcloud}"
  done
done
gtk-update-icon-cache -f /usr/share/icons/hicolor/

rm -r /tmp/nextcloud_desktop/
