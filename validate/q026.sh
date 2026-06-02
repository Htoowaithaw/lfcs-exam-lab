#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

[ -x /usr/local/bin/q026-greet.sh ] || fail "script missing or not executable"
[ "$(/usr/local/bin/q026-greet.sh)" = "Hello, LFCS" ] || fail "default greeting incorrect"
[ "$(/usr/local/bin/q026-greet.sh Ada)" = "Hello, Ada" ] || fail "argument greeting incorrect"
echo "RESULT: PASS"
