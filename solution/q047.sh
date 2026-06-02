#!/usr/bin/env bash
set -euo pipefail
cd /var/tmp/ec-q047/tree && find . -type f -perm -0002 -printf '%P\n' | sort > /root/q047-world-writable.txt
