#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcs-nfs2 >/dev/null 2>&1 || true
rm -rf /mnt/lfcs-nfs2
sed -i '\#/mnt/lfcs-nfs2#d' /etc/fstab
