RUN echo "install esp4 /bin/false" > /etc/modprobe.d/dirtyfrag.conf && \
    echo "install esp6 /bin/false" >> /etc/modprobe.d/dirtyfrag.conf && \
    echo "install rxrpc /bin/false" >> /etc/modprobe.d/dirtyfrag.conf