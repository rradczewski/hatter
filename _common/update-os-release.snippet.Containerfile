ARG HAT
ENV HAT=$HAT

ARG VERSION
ENV VERSION=$VERSION

RUN \
	--mount=type=bind,source=./_common,target=/_common \
	bash /_common/update-os-release.sh
