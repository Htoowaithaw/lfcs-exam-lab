#!/usr/bin/env bash
set -euo pipefail
rm -f /etc/sysctl.d/lfcs-op-sysctl1.conf
sysctl -w net.ipv4.ip_forward=0 >/dev/null 2>&1 || true
