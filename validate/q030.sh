#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q030-matches.txt ] || fail "matches file missing"
[ "$(cat /root/q030-matches.txt)" = $'ERROR disk full\nERROR backup failed' ] || fail "matches content incorrect"
echo "RESULT: PASS"
