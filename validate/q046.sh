#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q046-recent-conf.txt ] || fail "output file missing"
[ "$(cat /root/q046-recent-conf.txt)" = $'app/new.conf\nroot.conf' ] || fail "find result incorrect"
echo "RESULT: PASS"
