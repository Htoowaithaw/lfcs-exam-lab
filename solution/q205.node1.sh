#!/usr/bin/env bash
set -euo pipefail
modprobe nbd max_part=8
nbd-client -d /dev/nbd0 >/dev/null 2>&1 || true
sleep 2
nbd-client 192.168.56.12 -N lfcsnbd1 /dev/nbd0
mkfs.ext4 -F -L lfcsnbd1 /dev/nbd0
mkdir -p /mnt/lfcsnbd1
mount /dev/nbd0 /mnt/lfcsnbd1
