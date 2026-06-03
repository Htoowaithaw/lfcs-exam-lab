#!/usr/bin/env bash
set -euo pipefail
pvcreate -ff -y /dev/sdg
vgcreate vglfcs3 /dev/sdg
lvcreate -y -L 88M -n lvdata3 vglfcs3
mkfs.ext4 -F /dev/vglfcs3/lvdata3
mkdir -p /mnt/lfcs-lvm3
mount /dev/vglfcs3/lvdata3 /mnt/lfcs-lvm3
