#!/usr/bin/env bash
set -euo pipefail
pvcreate -ff -y /dev/sdg
vgcreate vglfcs6 /dev/sdg
lvcreate -y -L 112M -n lvdata6 vglfcs6
mkfs.ext4 -F /dev/vglfcs6/lvdata6
mkdir -p /mnt/lfcs-lvm6
mount /dev/vglfcs6/lvdata6 /mnt/lfcs-lvm6
