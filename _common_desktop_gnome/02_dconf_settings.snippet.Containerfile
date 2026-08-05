COPY _common_desktop_gnome/02_dconf_settings/etc/dconf/db/local.d/* /etc/dconf/db/local.d/

RUN set -eux; \
    for uuid in \
        no-overview@fthx \
        gsconnect@andyholmes.github.io \
        appindicatorsupport@rgcjonas.gmail.com ; \
    do \
        test -f "/usr/share/gnome-shell/extensions/$uuid/metadata.json" \
            || { echo "missing extension: $uuid" >&2; exit 1; }; \
    done; \
    dconf update