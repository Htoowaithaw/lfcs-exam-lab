#!/usr/bin/env bash
set -euo pipefail
rm -f /etc/sysctl.d/lfcs-op-sysctl3.conf
sysctl -w kernel.dmesg_restrict=0 >/dev/null 2>&1 || true
