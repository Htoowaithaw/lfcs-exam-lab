#!/usr/bin/env bash
set -euo pipefail
if ! ip -4 addr show dev lfcsnet1 | grep -q '10.55.1.10/24'; then echo "RESULT: FAIL - missing IPv4 address"; exit 1; fi
if ! ip -6 addr show dev lfcsnet1 | grep -q 'fd00:55:1::10/64'; then echo "RESULT: FAIL - missing IPv6 address"; exit 1; fi
if ! getent hosts phase5d-net1.local | grep -q '10.55.1.10'; then echo "RESULT: FAIL - missing hosts entry"; exit 1; fi
echo "RESULT: PASS"
