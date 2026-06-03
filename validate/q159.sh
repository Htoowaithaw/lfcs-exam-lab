#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ "$(findmnt -rn -o TARGET /mnt/lfcs-opt4 2>/dev/null)" = '/mnt/lfcs-opt4' ] || fail 'mountpoint is not mounted'
[ "$(findmnt -rn -o SOURCE /mnt/lfcs-opt4 2>/dev/null)" = '/dev/sdf1' ] || fail 'wrong source device mounted'
[ "$(findmnt -rn -o FSTYPE /mnt/lfcs-opt4 2>/dev/null)" = 'ext4' ] || fail 'mounted filesystem is not ext4'
findmnt -no OPTIONS /mnt/lfcs-opt4 | tr ',' '\n' | grep -qx 'nosuid' || fail 'mount option is not active'
awk '$2 == "/mnt/lfcs-opt4" && $3 == "ext4" && $4 ~ /(^|,)nosuid(,|$)/ { found=1 } END { exit !found }' /etc/fstab || fail 'mount option is not persistent for requested mountpoint'
mount -a || fail 'mount -a failed'
echo "RESULT: PASS"
