#!/usr/bin/env bash
set -euo pipefail
mdadm --stop /dev/md/lfcsraid2 >/dev/null 2>&1 || true
rm -f /dev/md/lfcsraid2
swapoff /dev/sdh* >/dev/null 2>&1 || true
wipefs -a /dev/sdh* >/dev/null 2>&1 || true
dd if=/dev/zero of=/dev/sdh bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
swapoff /dev/sdi* >/dev/null 2>&1 || true
wipefs -a /dev/sdi* >/dev/null 2>&1 || true
dd if=/dev/zero of=/dev/sdi bs=1M count=8 conv=fsync >/dev/null 2>&1 || true
