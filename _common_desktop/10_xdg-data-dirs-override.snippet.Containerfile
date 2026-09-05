RUN mkdir -p /usr/share/xdg-overrides/applications && chmod 0755 /usr/share/xdg-overrides /usr/share/xdg-overrides/applications

COPY ./_common_desktop/10_xdg-data-dirs-override.generator /usr/lib/systemd/user-environment-generators/95-xdg-data-dirs-override
RUN chmod 0755 /usr/lib/systemd/user-environment-generators/95-xdg-data-dirs-override
