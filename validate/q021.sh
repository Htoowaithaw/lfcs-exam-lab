#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

f=/root/q021-zero.img
[ -f "$f" ] || fail "image missing"
[ "$(stat -c %s "$f")" -eq 10485760 ] || fail "image size incorrect"
cmp -n 10485760 "$f" /dev/zero >/dev/null || fail "image is not zero-filled"
echo "RESULT: PASS"
