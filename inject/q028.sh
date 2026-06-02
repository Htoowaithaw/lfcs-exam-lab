#!/usr/bin/env bash
set -euo pipefail
rm -f /usr/local/bin/q028-process.sh /root/q028-output.txt
rm -rf /tmp/q028.*
rm -rf /var/tmp/ec-q028
mkdir -p /var/tmp/ec-q028
printf 'alpha\nbeta\n' > /var/tmp/ec-q028/input.txt
