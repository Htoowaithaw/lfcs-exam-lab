#!/usr/bin/env bash
set -euo pipefail
cat > /etc/profile.d/lfcs-op-sec1.sh <<'EOF'
umask 027
TMOUT=601
readonly TMOUT
export TMOUT
EOF
chmod 0644 /etc/profile.d/lfcs-op-sec1.sh
