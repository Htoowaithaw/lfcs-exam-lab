#!/usr/bin/env bash
set -euo pipefail
swapoff /dev/sdf* >/dev/null 2>&1 || true
wipefs -a /dev/sdf* >/dev/null 2>&1 || true
dd if=/dev/zero of=/dev/sdf bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
umount /mnt/lfcs-opt1 >/dev/null 2>&1 || true
rm -rf /mnt/lfcs-opt1
sed -i '\#/mnt/lfcs-opt1#d' /etc/fstab
