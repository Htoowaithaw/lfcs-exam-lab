#!/usr/bin/env bash
set -euo pipefail
if ! blkid -o value -s TYPE /dev/sdd1 | grep -q '^ext4$'; then echo "RESULT: FAIL - filesystem type is not ext4"; exit 1; fi
if ! blkid -o value -s LABEL /dev/sdd1 | grep -q '^lfcsfs3$'; then echo "RESULT: FAIL - filesystem label is wrong"; exit 1; fi
echo "RESULT: PASS"
