#!/usr/bin/env bash
set -euo pipefail
cat > /etc/sysctl.d/lfcs-op-sysctl1.conf <<'EOF'
net.ipv4.ip_forward = 1
EOF
sysctl -w net.ipv4.ip_forward=1
