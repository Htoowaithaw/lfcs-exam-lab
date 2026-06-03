#!/usr/bin/env bash
set -euo pipefail
useradd -m -s /bin/bash limituser3
cat > /etc/security/limits.d/lfcs-limit3.conf <<'EOF'
limituser3 soft nofile 2051
limituser3 hard nofile 2051
EOF
