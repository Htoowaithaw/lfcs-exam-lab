#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcs-lvm3 >/dev/null 2>&1 || true
lvremove -ff /dev/vglfcs3/lvdata3 >/dev/null 2>&1 || true
vgremove -ff vglfcs3 >/dev/null 2>&1 || true
pvremove -ff -y /dev/sdg >/dev/null 2>&1 || true
swapoff /dev/sdg* >/dev/null 2>&1 || true
wipefs -a /dev/sdg* >/dev/null 2>&1 || true
dd if=/dev/zero of=/dev/sdg bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
rm -rf /mnt/lfcs-lvm3
