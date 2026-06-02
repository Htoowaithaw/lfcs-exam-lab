#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q032 /root/q032-active.conf
mkdir -p /var/tmp/ec-q032
cat >/var/tmp/ec-q032/sshd.conf <<'EOF'
# comment
Port 22

ListenAddress 0.0.0.0
#Banner none
EOF
