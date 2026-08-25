COPY ./_common_desktop_niri/04_gcr-ssh-agent-env.conf /etc/environment.d/60-gcr-ssh-agent.conf

RUN mkdir -p /usr/lib/systemd/user/sockets.target.wants && \
    ln -sf ../gcr-ssh-agent.socket \
        /usr/lib/systemd/user/sockets.target.wants/gcr-ssh-agent.socket
