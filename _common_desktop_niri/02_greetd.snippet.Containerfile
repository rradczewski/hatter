RUN useradd --system --shell /bin/false greeter
RUN systemctl enable greetd.service

COPY ./_common_desktop_niri/02_greetd_config.toml /etc/greetd/config.toml