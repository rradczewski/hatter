RUN echo "install algif_aead /bin/false" > /etc/modprobe.d/copyfail.conf
RUN echo 'kargs = ["initcall_blacklist=algif_aead_init"]' > /usr/lib/bootc/kargs.d/02_copyfail.kargs.toml