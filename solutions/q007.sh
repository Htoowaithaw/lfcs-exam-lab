#!/usr/bin/env bash
set -euo pipefail
mkfs.ext4 -F /var/tmp/lfcs-q007.img >/dev/null
mkdir -p /mnt/lfcs-q007
grep -q '/mnt/lfcs-q007' /etc/fstab || echo '/var/tmp/lfcs-q007.img /mnt/lfcs-q007 ext4 loop,defaults 0 0' >> /etc/fstab
mount /mnt/lfcs-q007
