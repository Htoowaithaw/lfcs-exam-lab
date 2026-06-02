#!/usr/bin/env bash
set -euo pipefail
rm -f /etc/sysctl.d/lfcs-op-sysctl2.conf
sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null 2>&1 || true
