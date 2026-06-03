#!/usr/bin/env bash
set -euo pipefail
printf 'label: dos
, 128M, L
' | sfdisk /dev/sdb
udevadm settle || true
