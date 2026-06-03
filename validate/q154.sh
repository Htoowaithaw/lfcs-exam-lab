#!/usr/bin/env bash
set -euo pipefail
if ! findmnt -rn /mnt/lfcs-fstab4 | grep -q '/mnt/lfcs-fstab4'; then echo "RESULT: FAIL - mountpoint is not mounted"; exit 1; fi
if ! grep -q 'UUID=.*/mnt/lfcs-fstab4.*lfcs-fstab-4' /etc/fstab; then echo "RESULT: FAIL - UUID fstab entry missing"; exit 1; fi
if ! mount -a; then echo "RESULT: FAIL - mount -a failed"; exit 1; fi
echo "RESULT: PASS"
