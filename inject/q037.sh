#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q037 /root/q037-http-ok.txt
mkdir -p /var/tmp/ec-q037
cat >/var/tmp/ec-q037/http.log <<'EOF'
GET / 200
POST /login 500
GET /old 301
DELETE /x 404
EOF
