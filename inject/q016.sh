#!/usr/bin/env bash
set -euo pipefail
rm -rf /etc/lfcs-q016
mkdir -p /etc/lfcs-q016
cat >/etc/lfcs-q016/motd <<'EOF'
temporary banner
remove this line
EOF
