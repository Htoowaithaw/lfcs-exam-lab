#!/usr/bin/env bash
set -euo pipefail
if ! blkid -o value -s TYPE /dev/sdd1 | grep -q '^ext4$'; then echo "RESULT: FAIL - filesystem type is not ext4"; exit 1; fi
if ! blkid -o value -s LABEL /dev/sdd1 | grep -q '^lfcsfs5$'; then echo "RESULT: FAIL - filesystem label is wrong"; exit 1; fi
if findmnt -rn -S /dev/sdd1 >/dev/null 2>&1; then echo "RESULT: FAIL - /dev/sdd1 must not be mounted"; exit 1; fi
echo "RESULT: PASS"
