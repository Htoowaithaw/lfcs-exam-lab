#!/usr/bin/env bash
set -euo pipefail
mkdir -p /mnt/lfcs-nfs4
grep -q '^192.168.56.12:/srv/lfcs-nfs4[[:space:]]\+/mnt/lfcs-nfs4[[:space:]]\+nfs' /etc/fstab || echo '192.168.56.12:/srv/lfcs-nfs4 /mnt/lfcs-nfs4 nfs ro,_netdev 0 0' >> /etc/fstab
mount -a
