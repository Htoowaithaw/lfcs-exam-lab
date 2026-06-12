#!/usr/bin/env bash
set -euo pipefail
if ! ip -4 addr show dev lfcsnet3 | grep -q '10.55.3.10/24'; then echo "RESULT: FAIL - missing IPv4 address"; exit 1; fi
if ! ip -6 addr show dev lfcsnet3 | grep -q 'fd00:55:3::10/64'; then echo "RESULT: FAIL - missing IPv6 address"; exit 1; fi
if ! getent hosts phase5d-net3.local | grep -q '10.55.3.10'; then echo "RESULT: FAIL - missing hosts entry"; exit 1; fi
ip link show dev lfcsnet3 | grep -Eq '<[^>]*UP[^>]*>' || { echo "RESULT: FAIL - interface is not up"; exit 1; }
echo "RESULT: PASS"
