#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
out=$(ls /root/q041-*.txt /root/q041-users.csv 2>/dev/null | head -n1 || true)
[ -n "$out" ] || fail "output file missing"
[ "$(cat "$out")" = $'alice,/bin/bash\nbob,/bin/sh' ] || fail "output content incorrect"
echo "RESULT: PASS"
