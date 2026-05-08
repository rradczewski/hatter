RUN echo "install algif_aead /bin/false" | tee /etc/modprobe.d/copyfail.conf
ADD ./_common/00_copyfail.kargs.toml /usr/lib/bootc/kargs.d/00_copyfail.kargs.toml
