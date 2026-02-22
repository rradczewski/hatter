ARG HAT
ENV HAT=$HAT

ARG VERSION
ENV VERSION=$VERSION

RUN \
	--mount=type=bind,source=./_common/update-os-release.sh,target=/_common/update-os-release.sh \
	bash /_common/update-os-release.sh
