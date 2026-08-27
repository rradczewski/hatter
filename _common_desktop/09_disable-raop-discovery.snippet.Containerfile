RUN mkdir -p /etc/pipewire/pipewire.conf.d && \
    printf 'context.properties = {\n    module.raop = false\n}\n' > /etc/pipewire/pipewire.conf.d/99-disable-raop.conf
