#!/usr/bin/env bash
set -euo pipefail
pvcreate -ff -y /dev/sdg
vgcreate vglfcs2 /dev/sdg
lvcreate -y -L 80M -n lvdata2 vglfcs2
mkfs.ext4 -F /dev/vglfcs2/lvdata2
mkdir -p /mnt/lfcs-lvm2
mount /dev/vglfcs2/lvdata2 /mnt/lfcs-lvm2
