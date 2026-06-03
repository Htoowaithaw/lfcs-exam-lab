#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcs-lvm1 >/dev/null 2>&1 || true
lvremove -ff /dev/vglfcs1/lvdata1 >/dev/null 2>&1 || true
vgremove -ff vglfcs1 >/dev/null 2>&1 || true
pvremove -ff -y /dev/sdg >/dev/null 2>&1 || true
swapoff /dev/sdg* >/dev/null 2>&1 || true
wipefs -a /dev/sdg* >/dev/null 2>&1 || true
dd if=/dev/zero of=/dev/sdg bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
rm -rf /mnt/lfcs-lvm1
