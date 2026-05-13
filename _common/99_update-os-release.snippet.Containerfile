ARG HAT
ARG VERSION

RUN \
	--mount=type=bind,source=./_common/99_update-os-release.sh,target=/_common/99_update-os-release.sh \
	VERSION=$VERSION \
	HAT=$HAT \
	bash /_common/99_update-os-release.sh
