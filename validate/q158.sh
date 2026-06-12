#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ "$(findmnt -rn -o TARGET /mnt/lfcs-opt3 2>/dev/null)" = '/mnt/lfcs-opt3' ] || fail 'mountpoint is not mounted'
[ "$(findmnt -rn -o SOURCE /mnt/lfcs-opt3 2>/dev/null)" = '/dev/sdf1' ] || fail 'wrong source device mounted'
[ "$(findmnt -rn -o FSTYPE /mnt/lfcs-opt3 2>/dev/null)" = 'ext4' ] || fail 'mounted filesystem is not ext4'
findmnt -no OPTIONS /mnt/lfcs-opt3 | tr ',' '\n' | grep -qx 'noexec' || fail 'mount option is not active'
awk '$2 == "/mnt/lfcs-opt3" && $3 == "ext4" && $4 ~ /(^|,)noexec(,|$)/ { found=1 } END { exit !found }' /etc/fstab || fail 'mount option is not persistent for requested mountpoint'
mount -a || fail 'mount -a failed'
spec="$(awk '$2=="/mnt/lfcs-opt3" && $3=="ext4" && $4 ~ /(^|,)noexec(,|$)/ {print $1; exit}' /etc/fstab)"
[ -n "$spec" ] || fail 'persistent source specification missing'
[ "$(readlink -f "$(findfs "$spec" 2>/dev/null)")" = '/dev/sdf1' ] || fail 'persistent entry does not reference /dev/sdf1'
echo "RESULT: PASS"
