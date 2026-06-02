#!/usr/bin/env bash
set -euo pipefail
find /var/tmp/ec-q048/tree -type d -empty -delete
cd /var/tmp/ec-q048/tree && find . -type d -printf '%P\n' | sed 's/^$/./' | sort > /root/q048-remaining-dirs.txt
