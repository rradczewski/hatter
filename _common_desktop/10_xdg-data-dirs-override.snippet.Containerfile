RUN mkdir -p /usr/share/xdg-overrides/applications && chmod 0755 /usr/share/xdg-overrides /usr/share/xdg-overrides/applications

COPY ./_common_desktop/10_xdg-data-dirs-override.generator /usr/lib/systemd/user-environment-generators/95-xdg-data-dirs-override
RUN chmod 0755 /usr/lib/systemd/user-environment-generators/95-xdg-data-dirs-override

# niri-session's blanket `systemctl --user import-environment` overwrites the
# generator's result (see zz_xdg-data-dirs-override.sh for details), so also
# reassert it at the shell/profile level, which niri-session does inherit from.
ADD ./_common_desktop/zz_xdg-data-dirs-override.sh /etc/profile.d/zz_xdg-data-dirs-override.sh
