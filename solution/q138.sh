#!/usr/bin/env bash
set -euo pipefail
printf 'label: dos
, 96M, L
' | sfdisk /dev/sdb
udevadm settle || true
