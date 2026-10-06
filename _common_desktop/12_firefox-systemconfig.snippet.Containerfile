# Flatpak Firefox reads system-wide prefs from the unmanaged org.mozilla.firefox.systemconfig extension.
# /var is only seeded on first deploy, so ship the content in /usr and symlink it into place via tmpfiles.
COPY ./_common_desktop/12_firefox-systemconfig/ /usr/share/hatter/firefox-systemconfig/
RUN printf 'L+ /var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/x86_64/stable - - - - /usr/share/hatter/firefox-systemconfig\n' \
    > /usr/lib/tmpfiles.d/hatter-firefox-systemconfig.conf
