# Caps Lock is grabbed by the host, so switch layouts with Alt+Caps Lock instead
RUN sed -i "s/^XKBOPTIONS=.*/XKBOPTIONS=grp:alt_caps_toggle/" /etc/vconsole.conf
