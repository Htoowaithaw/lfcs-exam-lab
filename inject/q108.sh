#!/usr/bin/env bash
set -euo pipefail
ip link delete lfcsnet4 >/dev/null 2>&1 || true
sed -i '/phase5d-net4.local/d' /etc/hosts
