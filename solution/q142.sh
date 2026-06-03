#!/usr/bin/env bash
set -euo pipefail
printf 'label: dos
, 160M, L
' | sfdisk /dev/sdb
udevadm settle || true
