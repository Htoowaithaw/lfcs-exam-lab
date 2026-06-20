#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
out=/root/q040-inventory.txt
[ -f "$out" ] || fail "output file missing (expected /root/q040-inventory.txt)"
[ "$(cat "$out")" = $'acl\nattr\ngit\nrsync' ] || fail "output content incorrect"
echo "RESULT: PASS"
