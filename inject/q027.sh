#!/usr/bin/env bash
set -euo pipefail
rm -f /usr/local/bin/q027-status-summary.sh /root/q027-summary.txt
rm -rf /var/tmp/ec-q027
mkdir -p /var/tmp/ec-q027
cat >/var/tmp/ec-q027/events.csv <<'EOF'
id,status
1,OK
2,FAIL
3,WARN
4,OK
5,FAIL
6,OK
EOF
