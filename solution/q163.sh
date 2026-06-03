#!/usr/bin/env bash
set -euo pipefail
pvcreate -ff -y /dev/sdg
vgcreate vglfcs4 /dev/sdg
lvcreate -y -L 96M -n lvdata4 vglfcs4
mkfs.ext4 -F /dev/vglfcs4/lvdata4
mkdir -p /mnt/lfcs-lvm4
mount /dev/vglfcs4/lvdata4 /mnt/lfcs-lvm4
