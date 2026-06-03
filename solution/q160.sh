#!/usr/bin/env bash
set -euo pipefail
pvcreate -ff -y /dev/sdg
vgcreate vglfcs1 /dev/sdg
lvcreate -y -L 72M -n lvdata1 vglfcs1
mkfs.ext4 -F /dev/vglfcs1/lvdata1
mkdir -p /mnt/lfcs-lvm1
mount /dev/vglfcs1/lvdata1 /mnt/lfcs-lvm1
