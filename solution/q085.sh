#!/usr/bin/env bash
set -euo pipefail
cat > /etc/sysctl.d/lfcs-op-sysctl2.conf <<'EOF'
net.ipv4.conf.all.rp_filter = 0
EOF
sysctl -w net.ipv4.conf.all.rp_filter=0
