#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q033-warn-counts.txt ] || fail "count file missing"
[ "$(cat /root/q033-warn-counts.txt)" = $'app.log:2\ndb.log:1' ] || fail "warning counts incorrect"
echo "RESULT: PASS"
