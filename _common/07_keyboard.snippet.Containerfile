RUN \
    for setting in KEYMAP=us XKBLAYOUT=us,de XKBOPTIONS=grp:caps_toggle; do \
        key="${setting%%=*}"; \
        if grep -q "^${key}=" /etc/vconsole.conf 2>/dev/null; then \
            sed -i "s/^${key}=.*/${setting}/" /etc/vconsole.conf; \
        else \
            echo "${setting}" >> /etc/vconsole.conf; \
        fi; \
    done
