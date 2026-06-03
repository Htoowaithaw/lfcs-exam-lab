#!/usr/bin/env bash
set -euo pipefail
sed -i '/192.168.56.11/d;/local stratum/d' /etc/chrony/chrony.conf
systemctl restart chrony || true
