#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q039 /root/q039-tickets.txt
mkdir -p /var/tmp/ec-q039
cat >/var/tmp/ec-q039/tickets.txt <<'EOF'
LFCS-1024
LFCS-12
ABC-9999
LFCS-9001
EOF
