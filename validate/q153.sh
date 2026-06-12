#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ "$(findmnt -rn -o TARGET /mnt/lfcs-fstab3 2>/dev/null)" = '/mnt/lfcs-fstab3' ] || fail 'mountpoint is not mounted'
[ "$(findmnt -rn -o FSTYPE /mnt/lfcs-fstab3 2>/dev/null)" = 'ext4' ] || fail 'mounted filesystem is not ext4'
src="$(findmnt -rn -o SOURCE /mnt/lfcs-fstab3)"
[ "$(blkid -o value -s LABEL "$src" 2>/dev/null)" = 'fstab3' ] || fail 'filesystem label is wrong'
awk '$1 ~ /^UUID=/ && $2 == "/mnt/lfcs-fstab3" && $3 == "ext4" { found=1 } END { exit !found }' /etc/fstab || fail 'UUID ext4 fstab entry missing'
mount -a || fail 'mount -a failed'
[ "$(readlink -f "$src")" = '/dev/sde1' ] || fail 'mounted source is not /dev/sde1'
uuid="$(blkid -o value -s UUID /dev/sde1 2>/dev/null)"
awk -v wanted="UUID=$uuid" '$1==wanted && $2=="/mnt/lfcs-fstab3" && $3=="ext4" {found=1} END{exit !found}' /etc/fstab || fail 'fstab UUID does not belong to /dev/sde1'
echo "RESULT: PASS"
