#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q045 /root/q045-large-logs.txt
mkdir -p /var/tmp/ec-q045/tree/a
printf x > /var/tmp/ec-q045/tree/small.log
dd if=/dev/zero of=/var/tmp/ec-q045/tree/big.log bs=2048 count=1 status=none
dd if=/dev/zero of=/var/tmp/ec-q045/tree/a/nested.log bs=2048 count=1 status=none
