#!/usr/bin/env bash
set -euo pipefail
printf 'label: dos
, 80M, L
' | sfdisk /dev/sdb
udevadm settle || true
