RUN \
	--mount=type=bind,source=./_common_meta/update-os-release.sh,target=/_common_meta/update-os-release.sh \
	VERSION=$VERSION \
	HAT=$HAT \
	bash /_common_meta/update-os-release.sh
