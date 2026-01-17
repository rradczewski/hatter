RUN \
	--mount=type=bind,source=./tmp/kernel_signing_key/kernel_signing_certificate_key.pem,destination=/var/lib/dkms/mok.pub \
	--mount=type=bind,source=./tmp/kernel_signing_key/kernel_signing_certificate_key.key,destination=/var/lib/dkms/mok.key \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
	dnf install -y https://zfsonlinux.github.io/fedora/zfs-release-3-0$(rpm --eval "%{dist}").noarch.rpm \
	&& dnf install -y kernel-devel-$(rpm -q kernel | cut -d- -f2-) zfs zfs-dkms zfs-dracut \
	&& dkms install -k $(rpm -q kernel | cut -d- -f2-) zfs/$(rpm -q --queryformat '%{VERSION}' zfs-dkms) \
	&& dracut -f --add-drivers "zfs" --verbose --regenerate-all
