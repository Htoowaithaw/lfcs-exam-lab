#!/usr/bin/env bash
set -euo pipefail
cat > /etc/sysctl.d/lfcs-op-sysctl3.conf <<'EOF'
kernel.dmesg_restrict = 1
EOF
sysctl -w kernel.dmesg_restrict=1
