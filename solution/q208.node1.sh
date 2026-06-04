#!/usr/bin/env bash
set -euo pipefail
modprobe nbd max_part=8
nbd-client -d /dev/nbd3 >/dev/null 2>&1 || true
sleep 2
nbd-client 192.168.56.12 -N lfcsnbd4 /dev/nbd3
mkfs.ext4 -F -L lfcsnbd4 /dev/nbd3
mkdir -p /mnt/lfcsnbd4
mount /dev/nbd3 /mnt/lfcsnbd4
