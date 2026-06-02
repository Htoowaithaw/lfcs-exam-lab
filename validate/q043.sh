#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q043-page.txt ] || fail "output file missing"
[ "$(cat /root/q043-page.txt)" = $'40: topic 40\n41: topic 41\n42: topic 42\n43: topic 43\n44: topic 44\n45: topic 45' ] || fail "output content incorrect"
echo "RESULT: PASS"
