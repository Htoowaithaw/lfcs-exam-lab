#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q022 /root/q022-audit.log.gz
mkdir -p /var/tmp/ec-q022
printf 'login ok\nlogin failed\nlogout ok\n' > /var/tmp/ec-q022/audit.log
