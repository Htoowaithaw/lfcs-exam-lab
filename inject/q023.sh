#!/usr/bin/env bash
set -euo pipefail
rm -f /usr/local/bin/q023-backup.sh /root/q023-backup.tar.gz
rm -rf /var/tmp/ec-q023
mkdir -p /var/tmp/ec-q023/data
printf 'one\n' > /var/tmp/ec-q023/data/one.txt
printf 'two\n' > /var/tmp/ec-q023/data/two.txt
