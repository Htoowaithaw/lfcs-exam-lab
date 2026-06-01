#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
ip route show 203.0.113.0/24 | grep -q 'via 10.0.2.2' || fail "route missing or wrong gateway"
echo "RESULT: PASS"
