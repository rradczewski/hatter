#!/usr/bin/env bash

# From https://github.com/ublue-os/bluefin/blob/686acf0695add70413d30f2ccba74c989d515905/build_files/base/00-image-info.sh

echo "::group:: ===$(basename "$0")==="

set -xeuo pipefail

IMAGE_PRETTY_NAME="Fedora Hat $HAT"
IMAGE_LIKE="fedora"
HOME_URL="https://github.com/rradczewski/hatter"
VERSION="${VERSION:-00.00000000}"

# OS Release File
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"${IMAGE_PRETTY_NAME} (Version: ${VERSION})\"|" /usr/lib/os-release
sed -i "s|^NAME=.*|NAME=\"$IMAGE_PRETTY_NAME\"|" /usr/lib/os-release
sed -i "s|^HOME_URL=.*|HOME_URL=\"$HOME_URL\"|" /usr/lib/os-release
sed -i "s|^VERSION=.*|VERSION=\"${VERSION} (${BASE_IMAGE_NAME^})\"|" /usr/lib/os-release
sed -i "s|^OSTREE_VERSION=.*|OSTREE_VERSION=\'${VERSION}\'|" /usr/lib/os-release

if [[ -n "${SHA_HEAD_SHORT:-}" ]]; then
  echo "BUILD_ID=\"$SHA_HEAD_SHORT\"" >>/usr/lib/os-release
fi

# Added in systemd 249.
# https://www.freedesktop.org/software/systemd/man/latest/os-release.html#IMAGE_ID=
echo "IMAGE_VERSION=\"${VERSION}\"" >> /usr/lib/os-release

# Fix issues caused by ID no longer being fedora
sed -i "s|^EFIDIR=.*|EFIDIR=\"fedora\"|" /usr/sbin/grub2-switch-to-blscfg

echo "::endgroup::"
