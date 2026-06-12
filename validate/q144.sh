#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
grep -qw '/dev/sdc1' /proc/swaps || fail 'swap is not active on /dev/sdc1'
[ "$(blkid -o value -s TYPE /dev/sdc1 2>/dev/null)" = 'swap' ] || fail 'partition is not swap'
awk '$1 ~ /^UUID=/ && ($2 == "none" || $2 == "swap") && $3 == "swap" { found=1 } END { exit !found }' /etc/fstab || fail 'UUID swap fstab entry missing'
uuid="$(blkid -o value -s UUID /dev/sdc1 2>/dev/null)"
awk -v wanted="UUID=$uuid" '$1==wanted && ($2=="none" || $2=="swap") && $3=="swap" {found=1} END{exit !found}' /etc/fstab || fail 'fstab entry does not reference /dev/sdc1 by its UUID'
echo "RESULT: PASS"
