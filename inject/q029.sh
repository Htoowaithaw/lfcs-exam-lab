#!/usr/bin/env bash
set -euo pipefail
rm -f /usr/local/bin/q029-filter.sh
rm -rf /var/tmp/ec-q029
mkdir -p /var/tmp/ec-q029
printf '3\n7\n12\n18\n' > /var/tmp/ec-q029/numbers.txt
