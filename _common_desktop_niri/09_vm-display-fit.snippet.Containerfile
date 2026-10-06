ADD --chmod=755 ./_common_desktop_niri/09_vm-display-fit/vm-display-fit.sh /usr/bin/vm-display-fit

ADD ./_common_desktop_niri/09_vm-display-fit/vm-display-fit.service /usr/lib/systemd/user/

ADD ./_common_desktop_niri/09_vm-display-fit/vm-display-fit.conf /etc/vm-display-fit.conf

RUN mkdir -p /usr/lib/systemd/user/graphical-session.target.wants && \
    ln -sf ../vm-display-fit.service \
        /usr/lib/systemd/user/graphical-session.target.wants/vm-display-fit.service
