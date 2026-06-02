#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q018 /root/q018-types.txt
mkdir -p /var/tmp/ec-q018/files/conf.d
printf 'plain text\n' > /var/tmp/ec-q018/files/readme.txt
printf 'compressed text\n' | gzip -c > /var/tmp/ec-q018/files/payload.gz
