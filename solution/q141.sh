#!/usr/bin/env bash
set -euo pipefail
printf 'label: dos
, 144M, L
' | sfdisk /dev/sdb
udevadm settle || true
