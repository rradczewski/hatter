ADD --chmod=755 ./_common_desktop_niri/07_sync-clipboard/sync-clipboard.sh /usr/bin/sync-clipboard

ADD ./_common_desktop_niri/07_sync-clipboard/sync-clipboard.service /usr/lib/systemd/user/

RUN mkdir -p /usr/lib/systemd/user/graphical-session.target.wants && \
    ln -sf ../sync-clipboard.service \
        /usr/lib/systemd/user/graphical-session.target.wants/sync-clipboard.service
