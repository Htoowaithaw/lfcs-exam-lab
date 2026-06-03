#!/usr/bin/env bash
set -euo pipefail
if ! ip link show brlfcs2 | grep -q 'state UP'; then echo "RESULT: FAIL - bridge is not up"; exit 1; fi
if ! bridge link | grep -q 'brd2a'; then echo "RESULT: FAIL - first bridge member missing"; exit 1; fi
if ! bridge link | grep -q 'brd2b'; then echo "RESULT: FAIL - second bridge member missing"; exit 1; fi
echo "RESULT: PASS"
