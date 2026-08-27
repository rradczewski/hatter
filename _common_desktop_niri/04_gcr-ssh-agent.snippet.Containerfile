RUN mkdir -p /usr/lib/systemd/user/sockets.target.wants && \
    ln -sf ../gcr-ssh-agent.socket \
        /usr/lib/systemd/user/sockets.target.wants/gcr-ssh-agent.socket
