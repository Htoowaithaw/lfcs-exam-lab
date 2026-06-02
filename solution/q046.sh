#!/usr/bin/env bash
set -euo pipefail
cd /var/tmp/ec-q046/tree && find . -type f -name '*.conf' -mtime -2 -printf '%P\n' | sort > /root/q046-recent-conf.txt
