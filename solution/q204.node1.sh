#!/usr/bin/env bash
set -euo pipefail
mkdir -p /mnt/lfcs-nfs6
grep -q '^192.168.56.12:/srv/lfcs-nfs6[[:space:]]\+/mnt/lfcs-nfs6[[:space:]]\+nfs' /etc/fstab || echo '192.168.56.12:/srv/lfcs-nfs6 /mnt/lfcs-nfs6 nfs ro,_netdev 0 0' >> /etc/fstab
mount -a
