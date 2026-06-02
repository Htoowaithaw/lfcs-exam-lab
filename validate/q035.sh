#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q035-ips.txt ] || fail "output file missing"
[ "$(cat /root/q035-ips.txt)" = $'192.0.2.10 app\n10.1.1.5 db' ] || fail "output content incorrect"
echo "RESULT: PASS"
