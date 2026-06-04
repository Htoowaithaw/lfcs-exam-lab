#!/usr/bin/env bash
set -euo pipefail
mkdir -p /mnt/lfcs-nfs3
grep -q '^192.168.56.12:/srv/lfcs-nfs3[[:space:]]\+/mnt/lfcs-nfs3[[:space:]]\+nfs' /etc/fstab || echo '192.168.56.12:/srv/lfcs-nfs3 /mnt/lfcs-nfs3 nfs ro,_netdev 0 0' >> /etc/fstab
mount -a
