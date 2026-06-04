#!/usr/bin/env bash
set -euo pipefail
modprobe nbd max_part=8
nbd-client -d /dev/nbd2 >/dev/null 2>&1 || true
sleep 2
nbd-client 192.168.56.12 -N lfcsnbd3 /dev/nbd2
mkfs.ext4 -F -L lfcsnbd3 /dev/nbd2
mkdir -p /mnt/lfcsnbd3
mount /dev/nbd2 /mnt/lfcsnbd3
