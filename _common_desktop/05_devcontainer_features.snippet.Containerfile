RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y setools-console selinux-policy-devel

RUN --mount=type=tmpfs,target=/tmp/build \
    --mount=type=bind,source=./_common_desktop/05_devcontainer_features/devcontainer_features.te,target=/tmp/build/devcontainer_features.te \
    make -C /tmp/build -f /usr/share/selinux/devel/Makefile devcontainer_features.pp && \
    semodule -i /tmp/build/devcontainer_features.pp && \
    semodule -l | grep -q devcontainer_features
