#!/usr/bin/env bash
set -euo pipefail
swapoff /dev/sdb* >/dev/null 2>&1 || true
wipefs -a /dev/sdb* >/dev/null 2>&1 || true
dd if=/dev/zero of=/dev/sdb bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
