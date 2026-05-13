RUN \
	--mount=type=bind,source=./_tooling/update-os-release.sh,target=/_tooling/update-os-release.sh \
	VERSION=$VERSION \
	HAT=$HAT \
	bash /_tooling/update-os-release.sh
