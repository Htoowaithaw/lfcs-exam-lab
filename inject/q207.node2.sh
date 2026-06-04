#!/usr/bin/env bash
set -euo pipefail
sed -i '/\[lfcsnbd3\]/,/^$/d' /etc/nbd-server/config || true
rm -f /srv/lfcsnbd3.img
systemctl restart nbd-server >/dev/null 2>&1 || true
