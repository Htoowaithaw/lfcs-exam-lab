#!/usr/bin/env bash
set -euo pipefail
mkdir -p /srv/lfcs-nfs2
echo 'NFS-2-OK' > /srv/lfcs-nfs2/data.txt
grep -q '^/srv/lfcs-nfs2[[:space:]]' /etc/exports || echo '/srv/lfcs-nfs2 192.168.56.11(ro,sync,no_subtree_check)' >> /etc/exports
systemctl enable --now nfs-server || systemctl enable --now nfs-kernel-server
exportfs -ra
