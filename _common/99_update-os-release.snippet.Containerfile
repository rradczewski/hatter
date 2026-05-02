ARG HAT
ENV HAT=$HAT

ARG VERSION
ENV VERSION=$VERSION

RUN \
	--mount=type=bind,source=./_common/99_update-os-release.sh,target=/_common/99_update-os-release.sh \
	bash /_common/99_update-os-release.sh
