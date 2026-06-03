#!/usr/bin/env bash
set -euo pipefail
cat > /etc/profile.d/lfcs-profile2.sh <<'EOF'
export LFCS_PROFILE_2=enabled2
EOF
chmod 0644 /etc/profile.d/lfcs-profile2.sh
