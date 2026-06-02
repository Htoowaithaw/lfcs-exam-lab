#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

s=/usr/local/bin/q028-process.sh
[ -x "$s" ] || fail "script missing or not executable"
grep -Eq 'trap .*EXIT|trap .*0' "$s" || fail "EXIT trap missing"
rm -f /root/q028-output.txt
rm -rf /tmp/q028.*
"$s" || fail "script failed"
[ "$(cat /root/q028-output.txt 2>/dev/null)" = $'ALPHA\nBETA' ] || fail "uppercase output incorrect"
[ "$(find /tmp -maxdepth 1 -type d -name 'q028.*' -print -quit)" = "" ] || fail "temp directory not cleaned"
echo "RESULT: PASS"
