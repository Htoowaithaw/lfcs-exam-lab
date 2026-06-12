#!/usr/bin/env bash
set -euo pipefail
if ! mdadm --detail /dev/md/lfcsraid2 | grep -q 'Raid Level : raid1'; then echo "RESULT: FAIL - RAID level is not raid1"; exit 1; fi
if ! mdadm --detail /dev/md/lfcsraid2 | grep -q 'Raid Devices : 2'; then echo "RESULT: FAIL - RAID device count is wrong"; exit 1; fi
if ! blkid -o value -s TYPE /dev/md/lfcsraid2 | grep -q '^ext4$'; then echo "RESULT: FAIL - RAID filesystem is not ext4"; exit 1; fi
mdadm --detail /dev/md/lfcsraid2 | grep -Eq '[[:space:]]/dev/sdh$' || { echo "RESULT: FAIL - /dev/sdh is not an array member"; exit 1; }
mdadm --detail /dev/md/lfcsraid2 | grep -Eq '[[:space:]]/dev/sdi$' || { echo "RESULT: FAIL - /dev/sdi is not an array member"; exit 1; }
echo "RESULT: PASS"
