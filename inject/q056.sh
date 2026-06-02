#!/usr/bin/env bash
set -euo pipefail
chattr -i /srv/ec-q056/locked.conf >/dev/null 2>&1 || true
rm -rf /srv/ec-q056
mkdir -p /srv/ec-q056
printf 'secret\n' > /srv/ec-q056/locked.conf
chmod 0600 /srv/ec-q056/locked.conf
