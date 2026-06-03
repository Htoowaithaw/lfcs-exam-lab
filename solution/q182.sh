#!/usr/bin/env bash
set -euo pipefail
cat > /etc/profile.d/lfcs-profile1.sh <<'EOF'
export LFCS_PROFILE_1=enabled1
EOF
chmod 0644 /etc/profile.d/lfcs-profile1.sh
