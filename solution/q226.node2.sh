#!/usr/bin/env bash
set -euo pipefail
useradd -m -s /bin/bash remoteuser2
install -d -m 700 -o remoteuser2 -g remoteuser2 /home/remoteuser2/.ssh
cat /vagrant/.tmp-q226.pub > /home/remoteuser2/.ssh/authorized_keys
chown -R remoteuser2:remoteuser2 /home/remoteuser2/.ssh
chmod 600 /home/remoteuser2/.ssh/authorized_keys
systemctl enable --now ssh
systemctl restart ssh
