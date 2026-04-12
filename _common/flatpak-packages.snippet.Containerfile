ADD ./_common/flatpak-packages/*.service /etc/systemd/system/

RUN ln -s /etc/systemd/system/flatpak-remote-flathub.service \
          /etc/systemd/system/multi-user.target.wants/flatpak-remote-flathub.service && \
    ln -s /etc/systemd/system/flatpak-remote-fedora.service \
          /etc/systemd/system/multi-user.target.wants/flatpak-remote-fedora.service

RUN \
	--mount=type=bind,source=./_common/flatpak-packages/packages.fedora.list,target=/_common/flatpak-packages/packages.fedora.list \
    cat /_common/flatpak-packages/packages.fedora.list | xargs -I '{}' ln -s /etc/systemd/system/flatpak-install-fedora@.service /etc/systemd/system/multi-user.target.wants/flatpak-install-flathub@$(systemd-escape '{}').service

RUN \
	--mount=type=bind,source=./_common/flatpak-packages/packages.flathub.list,target=/_common/flatpak-packages/packages.flathub.list \
    cat /_common/flatpak-packages/packages.flathub.list | xargs -I '{}' ln -s /etc/systemd/system/flatpak-install-flathub@.service /etc/systemd/system/multi-user.target.wants/flatpak-install-flathub@$(systemd-escape '{}').service
