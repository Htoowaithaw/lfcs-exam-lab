#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q034 /root/q034-services.txt
mkdir -p /var/tmp/ec-q034
cat >/var/tmp/ec-q034/services.txt <<'EOF'
alpha01
beta1
gamma99
delta
EOF
