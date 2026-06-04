#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcs-nfs5 >/dev/null 2>&1 || true
rm -rf /mnt/lfcs-nfs5
sed -i '\#/mnt/lfcs-nfs5#d' /etc/fstab
