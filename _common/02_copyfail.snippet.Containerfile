COPY <<EOF /etc/modprobe.d/copyfail.conf
install algif_aead /bin/false
EOF

COPY <<EOF /usr/lib/bootc/kargs.d/02_copyfail.kargs.toml
kargs = ["initcall_blacklist=algif_aead_init"]
EOF
