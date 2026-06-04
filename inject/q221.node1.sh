#!/usr/bin/env bash
set -euo pipefail
sed -i '/192.168.56.12/d;/lfcs-ntp/d' /etc/chrony/chrony.conf
systemctl restart chrony || true
