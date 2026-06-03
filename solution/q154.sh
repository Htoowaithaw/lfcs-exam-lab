#!/usr/bin/env bash
set -euo pipefail
printf 'label: dos
, 192M, L
' | sfdisk /dev/sde
udevadm settle || true
mkfs.ext4 -F -L fstab4 /dev/sde1
mkdir -p /mnt/lfcs-fstab4
uuid=$(blkid -s UUID -o value /dev/sde1)
echo "UUID=$uuid /mnt/lfcs-fstab4 ext4 defaults 0 2 # lfcs-fstab-4" >> /etc/fstab
mount -a
