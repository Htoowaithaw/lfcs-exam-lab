#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

[ -x /usr/local/bin/q025-shell-report.sh ] || fail "script missing or not executable"
rm -f /root/q025-bash-users.txt
/usr/local/bin/q025-shell-report.sh || fail "script failed"
[ "$(cat /root/q025-bash-users.txt 2>/dev/null)" = $'adam\nzara' ] || fail "bash user report incorrect"
echo "RESULT: PASS"
