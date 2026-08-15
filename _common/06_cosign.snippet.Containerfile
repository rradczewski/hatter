COPY --from=ghcr.io/sigstore/cosign/cosign:v3.1.3@sha256:6ca1127dc1e9ff19f3f2bfa214936813a86fbbf52919652eda49d393c888ad3c \
    /ko-app/cosign \
    /usr/bin/cosign