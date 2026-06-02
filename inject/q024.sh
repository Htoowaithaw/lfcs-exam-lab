#!/usr/bin/env bash
set -euo pipefail
rm -f /usr/local/bin/q024-count-fails.sh /root/q024-fail-count.txt
rm -rf /var/tmp/ec-q024
mkdir -p /var/tmp/ec-q024
cat >/var/tmp/ec-q024/auth.log <<'EOF'
OK alice
FAILED bob
FAILED carol
OK dave
FAILED erin
EOF
