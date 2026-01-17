ADD ./ibp14/tuxedo.repo /etc/yum.repos.d/tuxedo.repo

RUN \
	--mount=type=bind,source=./tmp/kernel_signing_key/kernel_signing_certificate_key.pem,destination=/var/lib/dkms/mok.pub \
	--mount=type=bind,source=./tmp/kernel_signing_key/kernel_signing_certificate_key.key,destination=/var/lib/dkms/mok.key \
	--mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
	dnf install -y tuxedo-drivers --setopt=tsflags=noscripts \
	&& dkms install -k $(rpm -q kernel | cut -d- -f2-) tuxedo-drivers/$(rpm -q --queryformat '%{VERSION}' tuxedo-drivers)

RUN \
	--mount=type=bind,source=./tmp/kernel_signing_key/kernel_signing_certificate_key.pem,destination=/var/lib/dkms/mok.pub \
	--mount=type=bind,source=./tmp/kernel_signing_key/kernel_signing_certificate_key.key,destination=/var/lib/dkms/mok.key \
	--mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
	dnf install -y tuxedo-yt6801 --setopt=tsflags=noscripts \
	&& dkms install -k $(rpm -q kernel | cut -d- -f2-) tuxedo-yt6801/$(rpm -q --queryformat '%{VERSION}' tuxedo-yt6801)
