ADD --chmod=755 ./_common_laptop/03_battery-logger/battery-logger.sh /usr/bin/battery-logger.sh

ADD ./_common_laptop/03_battery-logger/battery-logger-resume.service \
    ./_common_laptop/03_battery-logger/battery-logger.service \
    ./_common_laptop/03_battery-logger/battery-logger.timer \
    /usr/lib/systemd/system/

RUN set -eux; \
    for t in suspend.target hibernate.target suspend-then-hibernate.target; do \
        mkdir -p "/usr/lib/systemd/system/$t.wants"; \
        ln -sf ../battery-logger-resume.service \
            "/usr/lib/systemd/system/$t.wants/battery-logger-resume.service"; \
    done; \
    mkdir -p /usr/lib/systemd/system/timers.target.wants; \
    ln -sf ../battery-logger.timer \
        /usr/lib/systemd/system/timers.target.wants/battery-logger.timer