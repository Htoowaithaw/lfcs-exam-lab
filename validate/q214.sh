#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ "$(sysctl -n net.ipv4.ip_forward)" = '1' ] || fail 'ip_forward is not enabled'
iptables -t nat -S LFCSNAT | grep -q -- '--dport 18606 .*--to-destination 192.168.56.12:18606' || fail 'DNAT rule missing'
curl -fsS --max-time 5 http://192.168.56.11:18606/lfcs-nat-6.txt | grep -Fxq 'NAT-6-NODE2' || fail 'node1 port does not reach node2 backend'
echo "RESULT: PASS"
