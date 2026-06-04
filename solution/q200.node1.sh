#!/usr/bin/env bash
set -euo pipefail
mkdir -p /mnt/lfcs-nfs2
grep -q '^192.168.56.12:/srv/lfcs-nfs2[[:space:]]\+/mnt/lfcs-nfs2[[:space:]]\+nfs' /etc/fstab || echo '192.168.56.12:/srv/lfcs-nfs2 /mnt/lfcs-nfs2 nfs ro,_netdev 0 0' >> /etc/fstab
mount -a
