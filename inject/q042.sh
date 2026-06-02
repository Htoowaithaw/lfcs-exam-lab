#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q042 /root/q042-*.txt /root/q042-users.csv
mkdir -p /var/tmp/ec-q042
cat >/var/tmp/ec-q042/assets.txt <<'EOF'
router,20
laptop,10
EOF
cat >/var/tmp/ec-q042/owners.txt <<'EOF'
10,alice
20,bob
EOF
