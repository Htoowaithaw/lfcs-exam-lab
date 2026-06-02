#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q031-matches.txt ] || fail "matches file missing"
[ "$(cat /root/q031-matches.txt)" = $'GET /api/v1/users\nPOST /api/v1/orders' ] || fail "matches content incorrect"
echo "RESULT: PASS"
