#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
out=$(ls /root/q040-*.txt /root/q040-users.csv 2>/dev/null | head -n1 || true)
[ -n "$out" ] || fail "output file missing"
[ "$(cat "$out")" = $'acl\nattr\ngit\nrsync' ] || fail "output content incorrect"
echo "RESULT: PASS"
