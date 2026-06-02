#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q047 /root/q047-world-writable.txt
mkdir -p /var/tmp/ec-q047/tree/open /var/tmp/ec-q047/tree/closed
printf x > /var/tmp/ec-q047/tree/open/tmp.txt
printf x > /var/tmp/ec-q047/tree/closed/secret.txt
chmod 0666 /var/tmp/ec-q047/tree/open/tmp.txt
chmod 0644 /var/tmp/ec-q047/tree/closed/secret.txt
