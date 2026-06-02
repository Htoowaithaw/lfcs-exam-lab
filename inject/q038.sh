#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q038 /root/q038-prod-hosts.txt
mkdir -p /var/tmp/ec-q038
cat >/var/tmp/ec-q038/hosts.txt <<'EOF'
web01-prod
web1-prod
db12-prod
cache01-dev
EOF
