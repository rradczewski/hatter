RUN \
	--mount=type=secret,id=KERNEL_SIGNING_CERTIFICATE_PEM,target=/var/lib/dkms/mok.pub \
	--mount=type=secret,id=KERNEL_SIGNING_CERTIFICATE_KEY,target=/var/lib/dkms/mok.key \
	--mount=type=bind,source=./_common/00_validate_signing_key.sh,target=/_common/00_validate_signing_key.sh \
    bash /_common/00_validate_signing_key.sh