#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q035 /root/q035-ips.txt
mkdir -p /var/tmp/ec-q035
cat >/var/tmp/ec-q035/hosts.txt <<'EOF'
192.0.2.10 app
not-an-ip
10.1.1.5 db
server 203.0.113.9
EOF
