#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q031 /root/q031-matches.txt
mkdir -p /var/tmp/ec-q031
cat >/var/tmp/ec-q031/input.log <<'EOF'
INFO start
ERROR disk full
GET /api/v1/users
WARN cache
POST /api/v1/orders
ERROR backup failed
EOF
