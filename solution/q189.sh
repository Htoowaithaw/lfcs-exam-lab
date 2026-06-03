#!/usr/bin/env bash
set -euo pipefail
useradd -m -s /bin/bash limituser2
cat > /etc/security/limits.d/lfcs-limit2.conf <<'EOF'
limituser2 soft nofile 2050
limituser2 hard nofile 2050
EOF
