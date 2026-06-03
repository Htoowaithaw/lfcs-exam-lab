#!/usr/bin/env bash
set -euo pipefail
swapoff /dev/sdc* >/dev/null 2>&1 || true
wipefs -a /dev/sdc* >/dev/null 2>&1 || true
dd if=/dev/zero of=/dev/sdc bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
sed -i '\#/dev/sdc1#d;/lfcs-swap-1/d' /etc/fstab
