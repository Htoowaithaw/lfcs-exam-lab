#!/usr/bin/env bash
set -euo pipefail
swapoff /dev/sde* >/dev/null 2>&1 || true
wipefs -a /dev/sde* >/dev/null 2>&1 || true
dd if=/dev/zero of=/dev/sde bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
umount /mnt/lfcs-fstab1 >/dev/null 2>&1 || true
rm -rf /mnt/lfcs-fstab1
sed -i '\#/mnt/lfcs-fstab1#d;/lfcs-fstab-1/d' /etc/fstab
