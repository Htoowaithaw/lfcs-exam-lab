#!/usr/bin/env bash
set -euo pipefail
mkdir -p /srv/lfcs-nfs1
echo 'NFS-1-OK' > /srv/lfcs-nfs1/data.txt
grep -q '^/srv/lfcs-nfs1[[:space:]]' /etc/exports || echo '/srv/lfcs-nfs1 192.168.56.11(ro,sync,no_subtree_check)' >> /etc/exports
systemctl enable --now nfs-server || systemctl enable --now nfs-kernel-server
exportfs -ra
