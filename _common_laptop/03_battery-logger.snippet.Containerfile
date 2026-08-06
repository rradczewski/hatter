ADD ./_common_laptop/03_battery-logger/battery-logger-resume.service \
    ./_common_laptop/03_battery-logger/battery-logger.service \
    ./_common_laptop/03_battery-logger/battery-logger.timer \
    /usr/lib/systemd/system/

RUN systemctl preset \
    battery-logger-resume.service \
    battery-logger.service \
    battery-logger.timer