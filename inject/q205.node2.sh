#!/usr/bin/env bash
set -euo pipefail
sed -i '/\[lfcsnbd1\]/,/^$/d' /etc/nbd-server/config || true
rm -f /srv/lfcsnbd1.img
systemctl restart nbd-server >/dev/null 2>&1 || true
