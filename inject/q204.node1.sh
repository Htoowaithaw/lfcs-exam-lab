#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcs-nfs6 >/dev/null 2>&1 || true
rm -rf /mnt/lfcs-nfs6
sed -i '\#/mnt/lfcs-nfs6#d' /etc/fstab
