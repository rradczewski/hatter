RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
        cage \
        gtkgreet

RUN systemctl enable greetd.service

COPY ./_common_desktop_niri/02_greetd_config.toml /etc/greetd/config.toml