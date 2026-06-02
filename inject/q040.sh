#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q040 /root/q040-*.txt /root/q040-users.csv
mkdir -p /var/tmp/ec-q040
cat >/var/tmp/ec-q040/packages.txt <<'EOF'
rsync
git
acl
git
attr
rsync
EOF
