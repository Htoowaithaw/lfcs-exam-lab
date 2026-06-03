#!/usr/bin/env bash
set -euo pipefail
printf 'label: dos
, 128M, L
' | sfdisk /dev/sdc
udevadm settle || true
mkswap -L lfcs-swap-2 /dev/sdc1
uuid=$(blkid -s UUID -o value /dev/sdc1)
echo "UUID=$uuid none swap sw 0 0 # lfcs-swap-2" >> /etc/fstab
swapon /dev/sdc1
