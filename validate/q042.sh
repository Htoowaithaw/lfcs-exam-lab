#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
out=/root/q042-owners.txt
[ -f "$out" ] || fail "output file missing (expected /root/q042-owners.txt)"
[ "$(cat "$out")" = $'laptop=alice\nrouter=bob' ] || fail "output content incorrect"
echo "RESULT: PASS"
