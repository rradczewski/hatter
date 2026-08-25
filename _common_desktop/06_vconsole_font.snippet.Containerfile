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
