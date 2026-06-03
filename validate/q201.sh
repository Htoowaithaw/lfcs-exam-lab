#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ "$(findmnt -rn -o TARGET /mnt/lfcs-nfs3 2>/dev/null)" = '/mnt/lfcs-nfs3' ] || fail 'NFS mountpoint is not mounted'
findmnt -rn -o FSTYPE /mnt/lfcs-nfs3 2>/dev/null | grep -Eq '^nfs' || fail 'mount is not NFS'
[ "$(findmnt -rn -o SOURCE /mnt/lfcs-nfs3 2>/dev/null)" = '192.168.56.12:/srv/lfcs-nfs3' ] || fail 'wrong NFS source'
grep -Fxq 'NFS-3-OK' /mnt/lfcs-nfs3/data.txt || fail 'exported data is not readable from node1'
awk '$1=="192.168.56.12:/srv/lfcs-nfs3" && $2=="/mnt/lfcs-nfs3" && $3=="nfs" {found=1} END {exit !found}' /etc/fstab || fail 'persistent NFS fstab entry missing'
showmount -e 192.168.56.12 | awk '$1=="/srv/lfcs-nfs3" && $0 ~ /192.168.56.11/ {found=1} END {exit !found}' || fail 'node2 export is not visible to node1'
echo "RESULT: PASS"
