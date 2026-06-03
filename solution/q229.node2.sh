#!/usr/bin/env bash
set -euo pipefail
useradd -m -s /bin/bash remoteuser5
install -d -m 700 -o remoteuser5 -g remoteuser5 /home/remoteuser5/.ssh
cat /vagrant/.tmp-q229.pub > /home/remoteuser5/.ssh/authorized_keys
chown -R remoteuser5:remoteuser5 /home/remoteuser5/.ssh
chmod 600 /home/remoteuser5/.ssh/authorized_keys
systemctl enable --now ssh
systemctl restart ssh
