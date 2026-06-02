#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q047-world-writable.txt ] || fail "output file missing"
[ "$(cat /root/q047-world-writable.txt)" = $'open/tmp.txt' ] || fail "find result incorrect"
echo "RESULT: PASS"
