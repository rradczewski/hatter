RUN \
    --mount=type=cache,dst=/var/cache/dnf \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    dnf install -y terminus-fonts-console

RUN \
    if grep -q '^FONT=' /etc/vconsole.conf 2>/dev/null; then \
        sed -i 's/^FONT=.*/FONT=ter-v32b/' /etc/vconsole.conf; \
    else \
        echo 'FONT=ter-v32b' >> /etc/vconsole.conf; \
    fi

# The early boot log (before the real root takes over) runs off the font baked
# into the initramfs, not /etc/vconsole.conf on disk - without regenerating it
# here, that text stays on the stock small font until the next kernel update
# triggers a rebuild.
RUN dracut -f --regenerate-all
