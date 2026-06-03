#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcsnbd2 >/dev/null 2>&1 || true
nbd-client -d /dev/nbd1 >/dev/null 2>&1 || true
rm -rf /mnt/lfcsnbd2
