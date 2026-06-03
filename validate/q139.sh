#!/usr/bin/env bash
set -euo pipefail
if ! test -b /dev/sdb1; then echo "RESULT: FAIL - scratch partition missing"; exit 1; fi
if ! lsblk -bno SIZE /dev/sdb1 | awk '{exit !($1 >= 112*1024*1024 && $1 < (112+8)*1024*1024)}'; then echo "RESULT: FAIL - partition size is wrong"; exit 1; fi
echo "RESULT: PASS"
