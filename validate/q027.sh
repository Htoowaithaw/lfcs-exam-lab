#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

[ -x /usr/local/bin/q027-status-summary.sh ] || fail "script missing or not executable"
rm -f /root/q027-summary.txt
/usr/local/bin/q027-status-summary.sh || fail "script failed"
[ "$(cat /root/q027-summary.txt 2>/dev/null)" = $'OK=3\nWARN=1\nFAIL=2' ] || fail "summary incorrect"
echo "RESULT: PASS"
