#!/usr/bin/env bash
set -euo pipefail
swapoff /swap-lfcs >/dev/null 2>&1 || true
sed -i '\#/swap-lfcs#d' /etc/fstab
rm -f /swap-lfcs
