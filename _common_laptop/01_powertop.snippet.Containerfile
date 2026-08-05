RUN powertop --version

ADD ./_common_laptop/01_powertop.service \
    /etc/systemd/system/
