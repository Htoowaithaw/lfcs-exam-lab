#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q034-services.txt ] || fail "output file missing"
[ "$(cat /root/q034-services.txt)" = $'alpha01\ngamma99' ] || fail "output content incorrect"
echo "RESULT: PASS"
