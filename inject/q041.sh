#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q041 /root/q041-*.txt /root/q041-users.csv
mkdir -p /var/tmp/ec-q041
cat >/var/tmp/ec-q041/passwd.sample <<'EOF'
root:x:0:0::/root:/bin/bash
alice:x:1001:1001::/home/alice:/bin/bash
bob:x:1002:1002::/home/bob:/bin/sh
EOF
