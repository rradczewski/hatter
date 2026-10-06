COPY ./_common_desktop_niri/08_ibus_env.conf /etc/environment.d/90-ibus.conf

RUN mkdir -p /usr/lib/systemd/user/graphical-session.target.wants && \
    ln -sf ../org.freedesktop.IBus.session.generic.service \
        /usr/lib/systemd/user/graphical-session.target.wants/org.freedesktop.IBus.session.generic.service
