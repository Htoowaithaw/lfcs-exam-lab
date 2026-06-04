#!/usr/bin/env bash
set -euo pipefail
useradd -m -s /bin/bash remoteuser1
install -d -m 700 -o remoteuser1 -g remoteuser1 /home/remoteuser1/.ssh
cat /vagrant/.tmp-q225.pub > /home/remoteuser1/.ssh/authorized_keys
chown -R remoteuser1:remoteuser1 /home/remoteuser1/.ssh
chmod 600 /home/remoteuser1/.ssh/authorized_keys
systemctl enable --now ssh
systemctl restart ssh
