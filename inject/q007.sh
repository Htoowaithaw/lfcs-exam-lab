#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcs-q007 >/dev/null 2>&1 || true
sed -i '\#/mnt/lfcs-q007#d' /etc/fstab
rm -rf /mnt/lfcs-q007
rm -f /var/tmp/lfcs-q007.img
dd if=/dev/zero of=/var/tmp/lfcs-q007.img bs=1M count=64 status=none
