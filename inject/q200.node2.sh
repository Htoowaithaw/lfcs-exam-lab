#!/usr/bin/env bash
set -euo pipefail
exportfs -u 192.168.56.11:/srv/lfcs-nfs2 >/dev/null 2>&1 || true
sed -i '\#/srv/lfcs-nfs2#d' /etc/exports
rm -rf /srv/lfcs-nfs2
exportfs -ra || true
