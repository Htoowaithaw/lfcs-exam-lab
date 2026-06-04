#!/usr/bin/env bash
set -euo pipefail
useradd -m -s /bin/bash remoteuser4
install -d -m 700 -o remoteuser4 -g remoteuser4 /home/remoteuser4/.ssh
cat /vagrant/.tmp-q228.pub > /home/remoteuser4/.ssh/authorized_keys
chown -R remoteuser4:remoteuser4 /home/remoteuser4/.ssh
chmod 600 /home/remoteuser4/.ssh/authorized_keys
systemctl enable --now ssh
systemctl restart ssh
