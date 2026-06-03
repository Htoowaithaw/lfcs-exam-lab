#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ "$(findmnt -rn -o TARGET /mnt/lfcsnbd1 2>/dev/null)" = '/mnt/lfcsnbd1' ] || fail 'NBD filesystem is not mounted'
[ "$(findmnt -rn -o SOURCE /mnt/lfcsnbd1 2>/dev/null)" = '/dev/nbd0' ] || fail 'wrong NBD device mounted'
[ "$(findmnt -rn -o FSTYPE /mnt/lfcsnbd1 2>/dev/null)" = 'ext4' ] || fail 'NBD filesystem is not ext4'
[ "$(blkid -o value -s LABEL /dev/nbd0 2>/dev/null)" = 'lfcsnbd1' ] || fail 'NBD filesystem label is wrong'
timeout 3 bash -c '</dev/tcp/192.168.56.12/10809' || fail 'node2 NBD service is not reachable'
echo "RESULT: PASS"
