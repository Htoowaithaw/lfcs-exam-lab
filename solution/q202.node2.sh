#!/usr/bin/env bash
set -euo pipefail
mkdir -p /srv/lfcs-nfs4
echo 'NFS-4-OK' > /srv/lfcs-nfs4/data.txt
grep -q '^/srv/lfcs-nfs4[[:space:]]' /etc/exports || echo '/srv/lfcs-nfs4 192.168.56.11(ro,sync,no_subtree_check)' >> /etc/exports
systemctl enable --now nfs-server || systemctl enable --now nfs-kernel-server
exportfs -ra
