#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q019 /root/q019-change.diff
mkdir -p /var/tmp/ec-q019
cat >/var/tmp/ec-q019/original.txt <<'EOF'
alpha=1
beta=old
gamma=3
EOF
cat >/var/tmp/ec-q019/updated.txt <<'EOF'
alpha=1
beta=new
gamma=3
delta=4
EOF
