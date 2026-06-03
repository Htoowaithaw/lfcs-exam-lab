#!/usr/bin/env bash
set -euo pipefail
ip link delete lfcsnet3 >/dev/null 2>&1 || true
sed -i '/phase5d-net3.local/d' /etc/hosts
