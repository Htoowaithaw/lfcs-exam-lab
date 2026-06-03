#!/usr/bin/env bash
set -euo pipefail
mkdir -p /srv/lfcs-nfs3
echo 'NFS-3-OK' > /srv/lfcs-nfs3/data.txt
grep -q '^/srv/lfcs-nfs3[[:space:]]' /etc/exports || echo '/srv/lfcs-nfs3 192.168.56.11(ro,sync,no_subtree_check)' >> /etc/exports
systemctl enable --now nfs-server || systemctl enable --now nfs-kernel-server
exportfs -ra
