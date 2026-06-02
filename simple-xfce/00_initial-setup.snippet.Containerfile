RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y initial-setup initial-setup-gui 

RUN echo "RUN_INITIAL_SETUP=YES" > /etc/sysconfig/initial-setup
RUN systemctl enable initial-setup.service