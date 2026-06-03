#!/usr/bin/env bash
set -euo pipefail
printf 'label: dos
, 160M, L
' | sfdisk /dev/sdd
udevadm settle || true
mkfs.ext4 -F -L lfcsfs5 /dev/sdd1
