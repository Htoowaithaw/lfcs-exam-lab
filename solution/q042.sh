#!/usr/bin/env bash
set -euo pipefail
join -t, -1 2 -2 1 <(sort -t, -k2 /var/tmp/ec-q042/assets.txt) <(sort -t, -k1 /var/tmp/ec-q042/owners.txt) | awk -F, '{print $2"="$3}' | sort > /root/q042-owners.txt
