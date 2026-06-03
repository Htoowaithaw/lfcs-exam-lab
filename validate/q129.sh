#!/usr/bin/env bash
set -euo pipefail
if ! ip route show 198.51.2.0/24 | grep -q 'dev lo'; then echo "RESULT: FAIL - route does not use loopback"; exit 1; fi
if ! ip route show 198.51.2.0/24 | grep -q 'metric 2'; then echo "RESULT: FAIL - route metric is wrong"; exit 1; fi
echo "RESULT: PASS"
