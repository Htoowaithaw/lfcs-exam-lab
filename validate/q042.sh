#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
out=$(ls /root/q042-*.txt /root/q042-users.csv 2>/dev/null | head -n1 || true)
[ -n "$out" ] || fail "output file missing"
[ "$(cat "$out")" = $'laptop=alice\nrouter=bob' ] || fail "output content incorrect"
echo "RESULT: PASS"
