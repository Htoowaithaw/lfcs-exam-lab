#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
pvs /dev/sdg --noheadings -o pv_name | awk '$1 == "/dev/sdg" { found=1 } END { exit !found }' || fail 'PV missing on scratch disk'
vgs vglfcs5 --noheadings -o vg_name | awk '$1 == "vglfcs5" { found=1 } END { exit !found }' || fail 'VG missing'
lvs /dev/vglfcs5/lvdata5 --noheadings -o lv_name | awk '$1 == "lvdata5" { found=1 } END { exit !found }' || fail 'LV missing'
bytes="$(blockdev --getsize64 /dev/vglfcs5/lvdata5 2>/dev/null)"
awk -v b="$bytes" 'BEGIN { exit !(b >= 104*1024*1024 && b < (104+8)*1024*1024) }' || fail 'LV size is wrong'
[ "$(blkid -o value -s TYPE /dev/vglfcs5/lvdata5 2>/dev/null)" = 'ext4' ] || fail 'LV filesystem is not ext4'
[ "$(findmnt -rn -o TARGET /mnt/lfcs-lvm5 2>/dev/null)" = '/mnt/lfcs-lvm5' ] || fail 'LV is not mounted at requested path'
[ "$(findmnt -rn -o SOURCE /mnt/lfcs-lvm5 2>/dev/null)" = '/dev/mapper/vglfcs5-lvdata5' ] || fail 'wrong LV mounted at requested path'
[ "$(findmnt -rn -o FSTYPE /mnt/lfcs-lvm5 2>/dev/null)" = 'ext4' ] || fail 'mounted filesystem is not ext4'
echo "RESULT: PASS"
