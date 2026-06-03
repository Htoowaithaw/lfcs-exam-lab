#!/usr/bin/env bash
set -euo pipefail
pvcreate -ff -y /dev/sdg
vgcreate vglfcs8 /dev/sdg
lvcreate -y -L 128M -n lvdata8 vglfcs8
mkfs.ext4 -F /dev/vglfcs8/lvdata8
mkdir -p /mnt/lfcs-lvm8
mount /dev/vglfcs8/lvdata8 /mnt/lfcs-lvm8
