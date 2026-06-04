#!/usr/bin/env bash
set -euo pipefail
fallocate -l 128M /swap-lfcs
chmod 600 /swap-lfcs
mkswap /swap-lfcs >/dev/null
swapon /swap-lfcs
grep -q '/swap-lfcs' /etc/fstab || echo '/swap-lfcs none swap sw 0 0' >> /etc/fstab
