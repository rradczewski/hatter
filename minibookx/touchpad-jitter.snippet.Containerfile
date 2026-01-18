# See
# https://wiki.wellorder.net/wiki/chuwi-minibookx/
# https://forum.chuwi.com/t/minibook-x-n150-touchpad-twitch/52230/7

ADD ./minibookx/touchpad-jitter.hwdb /etc/udev/hwdb.d/99-chuwi-minibookx-touchpad-jitter.hwdb

RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install libinput-test libinput-utils