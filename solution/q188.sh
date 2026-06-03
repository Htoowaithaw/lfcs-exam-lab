#!/usr/bin/env bash
set -euo pipefail
useradd -m -s /bin/bash limituser1
cat > /etc/security/limits.d/lfcs-limit1.conf <<'EOF'
limituser1 soft nofile 2049
limituser1 hard nofile 2049
EOF
