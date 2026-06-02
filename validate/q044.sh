#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q044-first-screen.txt ] || fail "output file missing"
[ "$(cat /root/q044-first-screen.txt)" = $'line 1\nline 2\nline 3\nline 4\nline 5\nline 6\nline 7\nline 8\nline 9\nline 10\nline 11\nline 12' ] || fail "output content incorrect"
echo "RESULT: PASS"
