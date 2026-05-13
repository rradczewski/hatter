
RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
	--mount=type=secret,id=KERNEL_SIGNING_CERTIFICATE_PEM,target=/var/lib/dkms/mok.pub \
	--mount=type=secret,id=KERNEL_SIGNING_CERTIFICATE_KEY,target=/var/lib/dkms/mok.key \
	dnf install -y https://zfsonlinux.github.io/fedora/zfs-release-3-1$(rpm --eval "%{dist}").noarch.rpm \
	&& dnf install -y kernel-devel-$(rpm -q kernel | cut -d- -f2-) zfs zfs-dkms zfs-dracut

RUN \
	--mount=type=secret,id=KERNEL_SIGNING_CERTIFICATE_PEM,target=/var/lib/dkms/mok.pub \
	--mount=type=secret,id=KERNEL_SIGNING_CERTIFICATE_KEY,target=/var/lib/dkms/mok.key \
	dkms install -k $(rpm -q kernel | cut -d- -f2-) zfs/$(rpm -q --queryformat '%{VERSION}' zfs-dkms) \
	&& dracut -f --add-drivers "zfs" --verbose --regenerate-all
