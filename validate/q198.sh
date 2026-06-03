#!/usr/bin/env bash
set -euo pipefail
if ! passwd -S root | awk '{print $2}' | grep -q '^L$'; then echo "RESULT: FAIL - root account is not locked"; exit 1; fi
echo "RESULT: PASS"
