#!/usr/bin/env bash
set -euo pipefail
cat > /etc/profile.d/lfcs-profile3.sh <<'EOF'
export LFCS_PROFILE_3=enabled3
EOF
chmod 0644 /etc/profile.d/lfcs-profile3.sh
