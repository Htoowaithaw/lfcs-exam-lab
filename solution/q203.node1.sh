#!/usr/bin/env bash
set -euo pipefail
mkdir -p /mnt/lfcs-nfs5
grep -q '^192.168.56.12:/srv/lfcs-nfs5[[:space:]]\+/mnt/lfcs-nfs5[[:space:]]\+nfs' /etc/fstab || echo '192.168.56.12:/srv/lfcs-nfs5 /mnt/lfcs-nfs5 nfs ro,_netdev 0 0' >> /etc/fstab
mount -a
