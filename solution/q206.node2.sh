#!/usr/bin/env bash
set -euo pipefail
mkdir -p /srv
truncate -s 64M /srv/lfcsnbd2.img
chown nbd:nbd /srv/lfcsnbd2.img
chmod 660 /srv/lfcsnbd2.img
mkdir -p /etc/nbd-server
grep -q '^\[lfcsnbd2\]' /etc/nbd-server/config || printf '\n[lfcsnbd2]\nexportname = /srv/lfcsnbd2.img\n' >> /etc/nbd-server/config
systemctl enable --now nbd-server
systemctl restart nbd-server
