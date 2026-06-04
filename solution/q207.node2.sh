#!/usr/bin/env bash
set -euo pipefail
mkdir -p /srv
truncate -s 64M /srv/lfcsnbd3.img
chown nbd:nbd /srv/lfcsnbd3.img
chmod 660 /srv/lfcsnbd3.img
mkdir -p /etc/nbd-server
grep -q '^\[lfcsnbd3\]' /etc/nbd-server/config || printf '\n[lfcsnbd3]\nexportname = /srv/lfcsnbd3.img\n' >> /etc/nbd-server/config
systemctl enable --now nbd-server
systemctl restart nbd-server
