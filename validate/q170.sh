#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
report=/root/lfcs-storage-perf3.txt
[ -s "$report" ] || fail 'report file missing or empty'
for label in LSBLK DF READAHEAD; do [ "$(grep -Fx "$label" "$report" | wc -l)" -eq 1 ] || fail "$label label missing or duplicated"; done
l1=$(grep -nFx LSBLK "$report" | cut -d: -f1); l2=$(grep -nFx DF "$report" | cut -d: -f1); l3=$(grep -nFx READAHEAD "$report" | cut -d: -f1)
[ "$l1" -lt "$l2" ] && [ "$l2" -lt "$l3" ] || fail 'report sections are out of order'
sed -n "$((l1+1)),$((l2-1))p" "$report" | grep -Eq '(^|[[:space:]])sdb([[:space:]]|$)' || fail 'LSBLK section does not contain /dev/sdb'
sed -n "$((l2+1)),$((l3-1))p" "$report" | grep -Eq '^Filesystem[[:space:]]' || fail 'DF section header missing'
sed -n "$((l2+1)),$((l3-1))p" "$report" | awk '$NF=="/" {found=1} END{exit !found}' || fail 'DF section does not contain the root filesystem'
actual=$(sed -n "$((l3+1)),\$p" "$report" | awk 'NF{print $1; exit}')
expected=$(blockdev --getra /dev/sdb)
[[ "$actual" =~ ^[0-9]+$ ]] || fail 'READAHEAD value is not numeric'
[ "$actual" = "$expected" ] || fail 'READAHEAD value does not match /dev/sdb'
echo "RESULT: PASS"
