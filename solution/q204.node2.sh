#!/usr/bin/env bash
set -euo pipefail
mkdir -p /srv/lfcs-nfs6
echo 'NFS-6-OK' > /srv/lfcs-nfs6/data.txt
grep -q '^/srv/lfcs-nfs6[[:space:]]' /etc/exports || echo '/srv/lfcs-nfs6 192.168.56.11(ro,sync,no_subtree_check)' >> /etc/exports
systemctl enable --now nfs-server || systemctl enable --now nfs-kernel-server
exportfs -ra
