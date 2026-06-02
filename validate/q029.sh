#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

s=/usr/local/bin/q029-filter.sh
[ -x "$s" ] || fail "script missing or not executable"
if "$s" >/tmp/q029.noarg 2>&1; then fail "script succeeds without --min"; fi
[ "$("$s" --min 10)" = $'12\n18' ] || fail "filter output for min 10 incorrect"
[ "$("$s" --min 7)" = $'7\n12\n18' ] || fail "filter output for min 7 incorrect"
echo "RESULT: PASS"
