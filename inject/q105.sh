#!/usr/bin/env bash
set -euo pipefail
ip link delete lfcsnet1 >/dev/null 2>&1 || true
sed -i '/phase5d-net1.local/d' /etc/hosts
