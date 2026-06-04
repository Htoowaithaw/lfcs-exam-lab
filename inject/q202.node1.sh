#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcs-nfs4 >/dev/null 2>&1 || true
rm -rf /mnt/lfcs-nfs4
sed -i '\#/mnt/lfcs-nfs4#d' /etc/fstab
