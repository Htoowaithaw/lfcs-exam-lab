#!/usr/bin/env bash
set -euo pipefail
swapoff /dev/sdd* >/dev/null 2>&1 || true
wipefs -a /dev/sdd* >/dev/null 2>&1 || true
dd if=/dev/zero of=/dev/sdd bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
