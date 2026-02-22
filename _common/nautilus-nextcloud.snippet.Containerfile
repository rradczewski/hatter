RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
        nautilus-python

RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
	--mount=type=bind,source=./_common/nautilus-nextcloud.install.sh,target=/_common/nautilus-nextcloud.install.sh \
    --mount=type=tmpfs,dst=/tmp/nextcloud_desktop \
	bash /_common/nautilus-nextcloud.install.sh

