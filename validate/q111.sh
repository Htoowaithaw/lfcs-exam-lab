#!/usr/bin/env bash
set -euo pipefail
if ! getent hosts lfcs-host7.example | grep -q '192.0.2.7'; then echo "RESULT: FAIL - host does not resolve to requested address"; exit 1; fi
echo "RESULT: PASS"
