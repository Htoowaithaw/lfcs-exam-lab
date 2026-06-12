#!/usr/bin/env bash
set -euo pipefail
if ! ufw status | grep -q 'Status: active'; then echo "RESULT: FAIL - ufw is not active"; exit 1; fi
if ! ufw status | grep -q '18201/tcp.*ALLOW'; then echo "RESULT: FAIL - requested UFW port is not allowed"; exit 1; fi
ufw status verbose | grep -Fq 'Default: allow (incoming), allow (outgoing)' || { echo "RESULT: FAIL - UFW default policies are not both allow"; exit 1; }
echo "RESULT: PASS"
