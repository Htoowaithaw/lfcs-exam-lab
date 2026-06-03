#!/usr/bin/env bash
set -euo pipefail
exportfs -u 192.168.56.11:/srv/lfcs-nfs6 >/dev/null 2>&1 || true
sed -i '\#/srv/lfcs-nfs6#d' /etc/exports
rm -rf /srv/lfcs-nfs6
exportfs -ra || true
