#!/usr/bin/env bash
set -euo pipefail
useradd -m -s /bin/bash remoteuser3
install -d -m 700 -o remoteuser3 -g remoteuser3 /home/remoteuser3/.ssh
cat /vagrant/.tmp-q227.pub > /home/remoteuser3/.ssh/authorized_keys
chown -R remoteuser3:remoteuser3 /home/remoteuser3/.ssh
chmod 600 /home/remoteuser3/.ssh/authorized_keys
systemctl enable --now ssh
systemctl restart ssh
