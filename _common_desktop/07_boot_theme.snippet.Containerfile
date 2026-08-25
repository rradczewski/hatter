ADD ./_common_desktop/07_boot_theme.kargs.toml /usr/lib/bootc/kargs.d/00-boot-theme.toml

RUN \
    if grep -q '^GRUB_COLOR_NORMAL=' /etc/default/grub 2>/dev/null; then \
        sed -i 's/^GRUB_COLOR_NORMAL=.*/GRUB_COLOR_NORMAL="cyan\/black"/' /etc/default/grub; \
    else \
        echo 'GRUB_COLOR_NORMAL="cyan/black"' >> /etc/default/grub; \
    fi
RUN \
    if grep -q '^GRUB_COLOR_HIGHLIGHT=' /etc/default/grub 2>/dev/null; then \
        sed -i 's/^GRUB_COLOR_HIGHLIGHT=.*/GRUB_COLOR_HIGHLIGHT="black\/light-magenta"/' /etc/default/grub; \
    else \
        echo 'GRUB_COLOR_HIGHLIGHT="black/light-magenta"' >> /etc/default/grub; \
    fi
