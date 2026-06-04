#!/usr/bin/env bash
set -euo pipefail
mkdir -p /srv
truncate -s 64M /srv/lfcsnbd1.img
chown nbd:nbd /srv/lfcsnbd1.img
chmod 660 /srv/lfcsnbd1.img
mkdir -p /etc/nbd-server
grep -q '^\[lfcsnbd1\]' /etc/nbd-server/config || printf '\n[lfcsnbd1]\nexportname = /srv/lfcsnbd1.img\n' >> /etc/nbd-server/config
systemctl enable --now nbd-server
systemctl restart nbd-server
