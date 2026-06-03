#!/usr/bin/env bash
set -euo pipefail
ip link delete lfcsnet2 >/dev/null 2>&1 || true
sed -i '/phase5d-net2.local/d' /etc/hosts
