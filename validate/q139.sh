#!/usr/bin/env bash
set -euo pipefail
if ! test -b /dev/sdb1; then echo "RESULT: FAIL - scratch partition missing"; exit 1; fi
if ! lsblk -bno SIZE /dev/sdb1 | awk '{exit !($1 >= 112*1024*1024 && $1 < (112+8)*1024*1024)}'; then echo "RESULT: FAIL - partition size is wrong"; exit 1; fi
[ "$(sfdisk --dump /dev/sdb | grep -Ec '^/dev/sdb[0-9]+ :')" -eq 1 ] || { echo "RESULT: FAIL - scratch disk must contain exactly one partition"; exit 1; }
sfdisk --dump /dev/sdb | grep -Eq '^/dev/sdb1 :.*type=83([,[:space:]]|$)' || { echo "RESULT: FAIL - partition type is not Linux (83)"; exit 1; }
echo "RESULT: PASS"
