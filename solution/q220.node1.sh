#!/usr/bin/env bash
set -euo pipefail
sed -i '/^pool /d;/^server /d' /etc/chrony/chrony.conf
echo 'server 192.168.56.12 iburst' >> /etc/chrony/chrony.conf
systemctl enable --now chrony
systemctl restart chrony
sleep 3
chronyc -a makestep >/dev/null 2>&1 || true
