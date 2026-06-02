#!/usr/bin/env bash
set -euo pipefail
nl -ba /var/tmp/ec-q043/manual.txt | awk '$1>=40 && $1<=45 {printf "%s: %s\n", $1, substr($0, index($0,$2))}' > /root/q043-page.txt
