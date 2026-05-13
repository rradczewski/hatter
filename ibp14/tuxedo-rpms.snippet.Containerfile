ADD ./ibp14/tuxedo.repo /etc/yum.repos.d/tuxedo.repo

RUN \
	--mount=type=secret,id=KERNEL_SIGNING_CERTIFICATE_PEM,target=/var/lib/dkms/mok.pub \
	--mount=type=secret,id=KERNEL_SIGNING_CERTIFICATE_KEY,target=/var/lib/dkms/mok.key \
	--mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
	dnf install -y tuxedo-drivers --setopt=tsflags=noscripts \
	&& dkms install -k $(rpm -q kernel | cut -d- -f2-) tuxedo-drivers/$(rpm -q --queryformat '%{VERSION}' tuxedo-drivers)

RUN \
	--mount=type=secret,id=KERNEL_SIGNING_CERTIFICATE_PEM,target=/var/lib/dkms/mok.pub \
	--mount=type=secret,id=KERNEL_SIGNING_CERTIFICATE_KEY,target=/var/lib/dkms/mok.key \
	--mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
	dnf install -y tuxedo-yt6801-0:1.0.30tux5-1 --setopt=tsflags=noscripts \
	&& dkms install -k $(rpm -q kernel | cut -d- -f2-) tuxedo-yt6801/$(rpm -q --queryformat '%{VERSION}' tuxedo-yt6801)
