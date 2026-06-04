#!/usr/bin/env bash
set -euo pipefail
mkdir -p /srv/lfcs-nfs5
echo 'NFS-5-OK' > /srv/lfcs-nfs5/data.txt
grep -q '^/srv/lfcs-nfs5[[:space:]]' /etc/exports || echo '/srv/lfcs-nfs5 192.168.56.11(ro,sync,no_subtree_check)' >> /etc/exports
systemctl enable --now nfs-server || systemctl enable --now nfs-kernel-server
exportfs -ra
