#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcsnbd1 >/dev/null 2>&1 || true
nbd-client -d /dev/nbd0 >/dev/null 2>&1 || true
rm -rf /mnt/lfcsnbd1
