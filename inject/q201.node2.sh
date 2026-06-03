#!/usr/bin/env bash
set -euo pipefail
exportfs -u 192.168.56.11:/srv/lfcs-nfs3 >/dev/null 2>&1 || true
sed -i '\#/srv/lfcs-nfs3#d' /etc/exports
rm -rf /srv/lfcs-nfs3
exportfs -ra || true
