#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcs-nfs1 >/dev/null 2>&1 || true
rm -rf /mnt/lfcs-nfs1
sed -i '\#/mnt/lfcs-nfs1#d' /etc/fstab
