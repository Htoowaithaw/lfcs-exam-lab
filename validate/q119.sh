#!/usr/bin/env bash
set -euo pipefail
if ! ip link show brlfcs3 | grep -q 'state UP'; then echo "RESULT: FAIL - bridge is not up"; exit 1; fi
if ! bridge link | grep -q 'brd3a'; then echo "RESULT: FAIL - first bridge member missing"; exit 1; fi
if ! bridge link | grep -q 'brd3b'; then echo "RESULT: FAIL - second bridge member missing"; exit 1; fi
for link in brd3a brd3b; do
  ip link show dev "$link" | grep -Eq '<[^>]*UP[^>]*>' || { echo "RESULT: FAIL - bridge member $link is not up"; exit 1; }
  bridge link show dev "$link" | grep -Fq "master brlfcs3" || { echo "RESULT: FAIL - $link is not attached to brlfcs3"; exit 1; }
done
echo "RESULT: PASS"
