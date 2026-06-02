#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q038-prod-hosts.txt ] || fail "output file missing"
[ "$(cat /root/q038-prod-hosts.txt)" = $'web01-prod\ndb12-prod' ] || fail "output content incorrect"
echo "RESULT: PASS"
