#!/usr/bin/env bash
set -euo pipefail
exportfs -u 192.168.56.11:/srv/lfcs-nfs1 >/dev/null 2>&1 || true
sed -i '\#/srv/lfcs-nfs1#d' /etc/exports
rm -rf /srv/lfcs-nfs1
exportfs -ra || true
