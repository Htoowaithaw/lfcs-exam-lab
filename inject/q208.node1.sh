#!/usr/bin/env bash
set -euo pipefail
umount /mnt/lfcsnbd4 >/dev/null 2>&1 || true
nbd-client -d /dev/nbd3 >/dev/null 2>&1 || true
rm -rf /mnt/lfcsnbd4
