#!/usr/bin/env bash
set -euo pipefail
modprobe nbd max_part=8
nbd-client -d /dev/nbd1 >/dev/null 2>&1 || true
sleep 2
nbd-client 192.168.56.12 -N lfcsnbd2 /dev/nbd1
mkfs.ext4 -F -L lfcsnbd2 /dev/nbd1
mkdir -p /mnt/lfcsnbd2
mount /dev/nbd1 /mnt/lfcsnbd2
