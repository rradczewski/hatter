RUN \
	--mount=type=secret,id=KERNEL_SIGNING_CERTIFICATE_PEM,target=/var/lib/dkms/mok.pub \
	--mount=type=secret,id=KERNEL_SIGNING_CERTIFICATE_KEY,target=/var/lib/dkms/mok.key \
    bash <<'EOF'
          set -uexo pipefail

          PUBKEY_FROM_PRIVATE_KEY=$(openssl pkey -pubout -in /var/lib/dkms/mok.key)
          PUBKEY_FROM_CERTIFICATE=$(openssl x509 -noout -pubkey -in /var/lib/dkms/mok.pub)
          if [ "$PUBKEY_FROM_CERTIFICATE" != "$PUBKEY_FROM_PRIVATE_KEY" ] || [ -z "$PUBKEY_FROM_CERTIFICATE" ] || [ -z "$PUBKEY_FROM_PRIVATE_KEY" ];
          then
            echo "Pubkeys don't match"
            exit 1
          fi
EOF