#!/usr/bin/env bash
set -euo pipefail
pvcreate -ff -y /dev/sdg
vgcreate vglfcs5 /dev/sdg
lvcreate -y -L 104M -n lvdata5 vglfcs5
mkfs.ext4 -F /dev/vglfcs5/lvdata5
mkdir -p /mnt/lfcs-lvm5
mount /dev/vglfcs5/lvdata5 /mnt/lfcs-lvm5
