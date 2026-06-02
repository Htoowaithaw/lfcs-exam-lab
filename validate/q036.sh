#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q036-users.txt ] || fail "output file missing"
[ "$(cat /root/q036-users.txt)" = $'alice\nbob2' ] || fail "output content incorrect"
echo "RESULT: PASS"
