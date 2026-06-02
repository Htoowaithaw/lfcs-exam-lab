#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q048-remaining-dirs.txt ] || fail "output file missing"
[ "$(cat /root/q048-remaining-dirs.txt)" = $'.\nkeep\nkeep/full' ] || fail "find result incorrect"
echo "RESULT: PASS"
