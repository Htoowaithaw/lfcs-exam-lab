#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q036 /root/q036-users.txt
mkdir -p /var/tmp/ec-q036
cat >/var/tmp/ec-q036/users.txt <<'EOF'
alice
Bob
bob2
carol-3
EOF
