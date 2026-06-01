#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
findmnt -n /mnt/lfcs-q007 >/dev/null 2>&1 || fail "mount missing"
[ "$(findmnt -n -o FSTYPE /mnt/lfcs-q007)" = "ext4" ] || fail "filesystem is not ext4"
grep -Eq '^[^#]*\/var\/tmp\/lfcs-q007\.img[[:space:]]+/mnt/lfcs-q007[[:space:]]+ext4[[:space:]].*loop' /etc/fstab || fail "persistent loop fstab entry missing"
echo "RESULT: PASS"
