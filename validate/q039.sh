#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q039-tickets.txt ] || fail "output file missing"
[ "$(cat /root/q039-tickets.txt)" = $'LFCS-1024\nLFCS-9001' ] || fail "output content incorrect"
echo "RESULT: PASS"
