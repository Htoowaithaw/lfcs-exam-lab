#!/usr/bin/env bash
set -euo pipefail
dd if=/dev/zero of=/root/q021-zero.img bs=1M count=10 status=none
