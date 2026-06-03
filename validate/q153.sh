#!/usr/bin/env bash
set -euo pipefail
if ! findmnt -rn /mnt/lfcs-fstab3 | grep -q '/mnt/lfcs-fstab3'; then echo "RESULT: FAIL - mountpoint is not mounted"; exit 1; fi
if ! grep -q 'UUID=.*/mnt/lfcs-fstab3.*lfcs-fstab-3' /etc/fstab; then echo "RESULT: FAIL - UUID fstab entry missing"; exit 1; fi
if ! mount -a; then echo "RESULT: FAIL - mount -a failed"; exit 1; fi
echo "RESULT: PASS"
