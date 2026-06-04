#!/usr/bin/env bash
set -euo pipefail
sed -i 's/^passwd:.*/passwd:         files systemd/' /etc/nsswitch.conf
systemctl restart nslcd >/dev/null 2>&1 || true
