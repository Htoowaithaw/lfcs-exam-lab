#!/usr/bin/env bash
set -euo pipefail
mkdir -p /srv
truncate -s 64M /srv/lfcsnbd4.img
chown nbd:nbd /srv/lfcsnbd4.img
chmod 660 /srv/lfcsnbd4.img
mkdir -p /etc/nbd-server
grep -q '^\[lfcsnbd4\]' /etc/nbd-server/config || printf '\n[lfcsnbd4]\nexportname = /srv/lfcsnbd4.img\n' >> /etc/nbd-server/config
systemctl enable --now nbd-server
systemctl restart nbd-server
