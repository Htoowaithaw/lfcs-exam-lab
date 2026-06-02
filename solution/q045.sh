#!/usr/bin/env bash
set -euo pipefail
find /var/tmp/ec-q045/tree -type f -name '*.log' -size +1k -printf '%f\n' | sort > /root/q045-large-logs.txt
