#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
grep -Eq '^server[[:space:]]+192.168.56.12[[:space:]]+iburst' /etc/chrony/chrony.conf || fail 'node1 chrony source is wrong'
systemctl is-active --quiet chrony || fail 'chrony is not active on node1'
chronyc sources -n | grep -q '192.168.56.12' || fail 'node2 is not listed as chrony source'
timeout 3 bash -c '</dev/udp/192.168.56.12/123' || true
echo "RESULT: PASS"
