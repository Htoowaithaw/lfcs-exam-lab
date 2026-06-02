#!/usr/bin/env bash
set -euo pipefail
for f in /var/tmp/ec-q033/logs/*.log; do printf '%s:%s\n' "$(basename "$f")" "$(grep -c 'WARN' "$f")"; done | sort > /root/q033-warn-counts.txt
