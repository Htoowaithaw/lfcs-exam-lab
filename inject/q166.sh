#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcs-lvm7 >/dev/null 2>&1 || true
lvremove -ff /dev/vglfcs7/lvdata7 >/dev/null 2>&1 || true
vgremove -ff vglfcs7 >/dev/null 2>&1 || true
pvremove -ff -y /dev/sdg >/dev/null 2>&1 || true
swapoff /dev/sdg* >/dev/null 2>&1 || true
wipefs -a /dev/sdg* >/dev/null 2>&1 || true
dd if=/dev/zero of=/dev/sdg bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
rm -rf /mnt/lfcs-lvm7
