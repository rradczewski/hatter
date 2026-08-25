RUN set -eux; \
    printf 'auth       optional     pam_gnome_keyring.so\n' >> /etc/pam.d/greetd; \
    printf 'session    optional     pam_gnome_keyring.so auto_start\n' >> /etc/pam.d/greetd
