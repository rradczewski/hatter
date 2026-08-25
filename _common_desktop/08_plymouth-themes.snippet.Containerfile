RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y curl plymouth-plugin-script

RUN \
    --mount=type=bind,source=./_common_desktop/08_plymouth-themes.install.sh,target=/_common_desktop/08_plymouth-themes.install.sh \
    --mount=type=tmpfs,dst=/tmp/plymouth-themes \
    bash /_common_desktop/08_plymouth-themes.install.sh

ADD --chmod=755 ./_common_desktop/08_plymouth-preview-theme.sh /usr/bin/plymouth-preview-theme
