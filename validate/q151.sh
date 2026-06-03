#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ "$(findmnt -rn -o TARGET /mnt/lfcs-fstab1 2>/dev/null)" = '/mnt/lfcs-fstab1' ] || fail 'mountpoint is not mounted'
[ "$(findmnt -rn -o FSTYPE /mnt/lfcs-fstab1 2>/dev/null)" = 'ext4' ] || fail 'mounted filesystem is not ext4'
src="$(findmnt -rn -o SOURCE /mnt/lfcs-fstab1)"
[ "$(blkid -o value -s LABEL "$src" 2>/dev/null)" = 'fstab1' ] || fail 'filesystem label is wrong'
awk '$1 ~ /^UUID=/ && $2 == "/mnt/lfcs-fstab1" && $3 == "ext4" { found=1 } END { exit !found }' /etc/fstab || fail 'UUID ext4 fstab entry missing'
mount -a || fail 'mount -a failed'
echo "RESULT: PASS"
