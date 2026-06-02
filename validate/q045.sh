#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q045-large-logs.txt ] || fail "output file missing"
[ "$(cat /root/q045-large-logs.txt)" = $'big.log\nnested.log' ] || fail "find result incorrect"
echo "RESULT: PASS"
