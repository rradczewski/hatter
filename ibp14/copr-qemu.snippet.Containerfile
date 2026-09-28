RUN dnf -y install 'dnf5-command(copr)' && \
    dnf -y copr enable @virtmaint-sig/virt-preview && \
    dnf -y upgrade 'qemu*' 'libvirt*' 'virglrenderer*' && \
    dnf clean all