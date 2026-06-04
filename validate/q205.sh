#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ "$(findmnt -rn -o TARGET /mnt/lfcsnbd1 2>/dev/null)" = '/mnt/lfcsnbd1' ] || fail 'NBD filesystem is not mounted'
[ "$(findmnt -rn -o SOURCE /mnt/lfcsnbd1 2>/dev/null)" = '/dev/nbd0' ] || fail 'wrong NBD device mounted'
[ "$(findmnt -rn -o FSTYPE /mnt/lfcsnbd1 2>/dev/null)" = 'ext4' ] || fail 'NBD filesystem is not ext4'
[ "$(blkid -o value -s LABEL /dev/nbd0 2>/dev/null)" = 'lfcsnbd1' ] || fail 'NBD filesystem label is wrong'
size=$(blockdev --getsize64 /dev/nbd0 2>/dev/null || echo 0)
[ "$size" -eq 67108864 ] || fail 'NBD device is not 64M'
timeout 3 bash -c '</dev/tcp/192.168.56.12/10809' || fail 'node2 NBD service is not reachable'
modprobe nbd max_part=8
nbd-client -d /dev/nbd7 >/dev/null 2>&1 || true
if ! timeout 10 nbd-client 192.168.56.12 -N lfcsnbd1 /dev/nbd7 >/dev/null 2>&1; then fail 'node2 NBD export name is missing'; fi
nbd-client -d /dev/nbd7 >/dev/null 2>&1 || true
echo "RESULT: PASS"
