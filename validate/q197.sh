#!/usr/bin/env bash
set -euo pipefail
if ! passwd -S root | awk '{print $2}' | grep -q '^P$'; then echo "RESULT: FAIL - root account is not unlocked"; exit 1; fi
echo "RESULT: PASS"
