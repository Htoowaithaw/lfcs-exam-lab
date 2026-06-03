#!/usr/bin/env bash
set -euo pipefail
printf 'label: dos
, 192M, L
' | sfdisk /dev/sde
udevadm settle || true
mkfs.ext4 -F -L fstab2 /dev/sde1
mkdir -p /mnt/lfcs-fstab2
uuid=$(blkid -s UUID -o value /dev/sde1)
echo "UUID=$uuid /mnt/lfcs-fstab2 ext4 defaults 0 2 # lfcs-fstab-2" >> /etc/fstab
mount -a
