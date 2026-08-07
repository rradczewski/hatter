RUN powertop --version

ADD ./_common_laptop/01_powertop.service \
    /usr/lib/systemd/system/powertop.service

RUN set -eux; \
    for t in multi-user.target sleep.target; do \
        mkdir -p "/usr/lib/systemd/system/$t.wants"; \
        ln -sf ../powertop.service \
            "/usr/lib/systemd/system/$t.wants/powertop.service"; \
    done