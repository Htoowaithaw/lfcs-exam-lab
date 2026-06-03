#!/usr/bin/env bash
set -euo pipefail
printf 'y\n' | mdadm --create /dev/md/lfcsraid3 --metadata=1.2 --level=1 --raid-devices=2 /dev/sdh /dev/sdi
udevadm settle || true
mkfs.ext4 -F /dev/md/lfcsraid3
