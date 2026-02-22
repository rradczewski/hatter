RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y \
        nautilus-python

RUN \
	--mount=type=bind,source=./_common/nautilus-nextcloud.install.sh,target=/_common/nautilus-nextcloud.install.sh \
	bash /_common/nautilus-nextcloud.install.sh

