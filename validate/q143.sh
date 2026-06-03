#!/usr/bin/env bash
set -euo pipefail
if ! grep -q '/dev/sdc1' /proc/swaps; then echo "RESULT: FAIL - swap is not active"; exit 1; fi
if ! blkid -o value -s TYPE /dev/sdc1 | grep -q '^swap$'; then echo "RESULT: FAIL - partition is not swap"; exit 1; fi
if ! grep -q 'lfcs-swap-1' /etc/fstab; then echo "RESULT: FAIL - persistent fstab marker missing"; exit 1; fi
echo "RESULT: PASS"
