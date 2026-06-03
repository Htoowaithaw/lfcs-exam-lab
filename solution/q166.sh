#!/usr/bin/env bash
set -euo pipefail
pvcreate -ff -y /dev/sdg
vgcreate vglfcs7 /dev/sdg
lvcreate -y -L 120M -n lvdata7 vglfcs7
mkfs.ext4 -F /dev/vglfcs7/lvdata7
mkdir -p /mnt/lfcs-lvm7
mount /dev/vglfcs7/lvdata7 /mnt/lfcs-lvm7
