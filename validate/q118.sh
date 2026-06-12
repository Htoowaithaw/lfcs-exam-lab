#!/usr/bin/env bash
set -euo pipefail
if ! ip link show brlfcs2 | grep -q 'state UP'; then echo "RESULT: FAIL - bridge is not up"; exit 1; fi
if ! bridge link | grep -q 'brd2a'; then echo "RESULT: FAIL - first bridge member missing"; exit 1; fi
if ! bridge link | grep -q 'brd2b'; then echo "RESULT: FAIL - second bridge member missing"; exit 1; fi
for link in brd2a brd2b; do
  ip link show dev "$link" | grep -Eq '<[^>]*UP[^>]*>' || { echo "RESULT: FAIL - bridge member $link is not up"; exit 1; }
  bridge link show dev "$link" | grep -Fq "master brlfcs2" || { echo "RESULT: FAIL - $link is not attached to brlfcs2"; exit 1; }
done
echo "RESULT: PASS"
