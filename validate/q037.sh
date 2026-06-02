#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q037-http-ok.txt ] || fail "output file missing"
[ "$(cat /root/q037-http-ok.txt)" = $'GET / 200\nGET /old 301' ] || fail "output content incorrect"
echo "RESULT: PASS"
