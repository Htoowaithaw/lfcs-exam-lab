#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

[ -x /usr/local/bin/q024-count-fails.sh ] || fail "script missing or not executable"
rm -f /root/q024-fail-count.txt
/usr/local/bin/q024-count-fails.sh || fail "script failed"
[ "$(cat /root/q024-fail-count.txt 2>/dev/null)" = "3" ] || fail "fail count incorrect"
echo "RESULT: PASS"
