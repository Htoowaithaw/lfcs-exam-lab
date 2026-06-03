#!/usr/bin/env bash
set -euo pipefail
printf 'label: dos
, 128M, L
' | sfdisk /dev/sdf
udevadm settle || true
mkfs.ext4 -F /dev/sdf1
mkdir -p /mnt/lfcs-opt2
uuid=$(blkid -s UUID -o value /dev/sdf1)
echo "UUID=$uuid /mnt/lfcs-opt2 ext4 defaults,nosuid 0 2" >> /etc/fstab
mount -a
