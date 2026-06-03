#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
pvs /dev/sdg --noheadings -o pv_name | awk '$1 == "/dev/sdg" { found=1 } END { exit !found }' || fail 'PV missing on scratch disk'
vgs vglfcs6 --noheadings -o vg_name | awk '$1 == "vglfcs6" { found=1 } END { exit !found }' || fail 'VG missing'
lvs /dev/vglfcs6/lvdata6 --noheadings -o lv_name | awk '$1 == "lvdata6" { found=1 } END { exit !found }' || fail 'LV missing'
bytes="$(blockdev --getsize64 /dev/vglfcs6/lvdata6 2>/dev/null)"
awk -v b="$bytes" 'BEGIN { exit !(b >= 112*1024*1024 && b < (112+8)*1024*1024) }' || fail 'LV size is wrong'
[ "$(blkid -o value -s TYPE /dev/vglfcs6/lvdata6 2>/dev/null)" = 'ext4' ] || fail 'LV filesystem is not ext4'
[ "$(findmnt -rn -o TARGET /mnt/lfcs-lvm6 2>/dev/null)" = '/mnt/lfcs-lvm6' ] || fail 'LV is not mounted at requested path'
[ "$(findmnt -rn -o SOURCE /mnt/lfcs-lvm6 2>/dev/null)" = '/dev/mapper/vglfcs6-lvdata6' ] || fail 'wrong LV mounted at requested path'
[ "$(findmnt -rn -o FSTYPE /mnt/lfcs-lvm6 2>/dev/null)" = 'ext4' ] || fail 'mounted filesystem is not ext4'
echo "RESULT: PASS"
