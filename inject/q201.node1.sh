#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcs-nfs3 >/dev/null 2>&1 || true
rm -rf /mnt/lfcs-nfs3
sed -i '\#/mnt/lfcs-nfs3#d' /etc/fstab
