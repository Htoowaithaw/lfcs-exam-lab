#!/usr/bin/env bash
set -euo pipefail
mkdir -p /var/www/html/lfcs-r01
echo "LFCS Rocky SELinux context" > /var/www/html/lfcs-r01/index.html
semanage fcontext -d '/var/www/html/lfcs-r01(/.*)?' >/dev/null 2>&1 || true
restorecon -RFv /var/www/html/lfcs-r01 >/dev/null 2>&1 || true
chcon -t default_t /var/www/html/lfcs-r01/index.html
