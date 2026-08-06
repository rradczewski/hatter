RUN powertop --version

ADD ./_common_laptop/01_powertop.service \
    /usr/lib/systemd/system/powertop.service

RUN systemctl preset powertop.service