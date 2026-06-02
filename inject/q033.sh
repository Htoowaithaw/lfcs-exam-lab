#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q033 /root/q033-warn-counts.txt
mkdir -p /var/tmp/ec-q033/logs
cat >/var/tmp/ec-q033/logs/app.log <<'EOF'
INFO start
WARN cache
WARN retry
EOF
cat >/var/tmp/ec-q033/logs/db.log <<'EOF'
WARN lag
INFO ok
EOF
