ADD ./_common_desktop/03_flatpak-packages/*.service /etc/systemd/system/

RUN ln -s /etc/systemd/system/flatpak-remote-flathub.service \
          /etc/systemd/system/multi-user.target.wants/flatpak-remote-flathub.service && \
    ln -s /etc/systemd/system/flatpak-remote-fedora.service \
          /etc/systemd/system/multi-user.target.wants/flatpak-remote-fedora.service

RUN \
	--mount=type=bind,source=./_common_desktop/03_flatpak-packages/packages.fedora.list,target=/_03_common_desktop/flatpak-packages/packages.fedora.list \
    cat /_common_desktop/03_flatpak-packages/packages.fedora.list | \
        xargs -n1 systemd-escape --template="flatpak-install-fedora@.service" | \
        xargs -I '{}' ln -s /etc/systemd/system/flatpak-install-fedora@.service /etc/systemd/system/multi-user.target.wants/{}

RUN \
	--mount=type=bind,source=./_common_desktop/03_flatpak-packages/packages.flathub.list,target=/_03_common_desktop/flatpak-packages/packages.flathub.list \
    cat /_common_desktop/03_flatpak-packages/packages.flathub.list | \
        xargs -n1 systemd-escape --template="flatpak-install-flathub@.service" | \
        xargs -I '{}' ln -s /etc/systemd/system/flatpak-install-flathub@.service /etc/systemd/system/multi-user.target.wants/{}
