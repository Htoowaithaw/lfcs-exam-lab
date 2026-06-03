#!/usr/bin/env bash
set -euo pipefail
if ! getent passwd lfcsuser4 | awk -F: '{exit !($3==2404 && $7=="/bin/bash")}'; then echo "RESULT: FAIL - user UID or shell is wrong"; exit 1; fi
if ! chage -l lfcsuser4 | grep -q 'Dec 31, 2030\|12/31/2030'; then echo "RESULT: FAIL - account expiry is wrong"; exit 1; fi
echo "RESULT: PASS"
