#!/usr/bin/env bash
set -euo pipefail
sed -i '/\[lfcsnbd4\]/,/^$/d' /etc/nbd-server/config || true
rm -f /srv/lfcsnbd4.img
systemctl restart nbd-server >/dev/null 2>&1 || true
