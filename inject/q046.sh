#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q046 /root/q046-recent-conf.txt
mkdir -p /var/tmp/ec-q046/tree/app
printf x > /var/tmp/ec-q046/tree/root.conf
printf x > /var/tmp/ec-q046/tree/app/new.conf
printf x > /var/tmp/ec-q046/tree/app/old.conf
touch -d '5 days ago' /var/tmp/ec-q046/tree/app/old.conf
