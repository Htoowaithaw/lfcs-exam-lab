#!/usr/bin/env bash
set -euo pipefail
mkdir -p /var/www/lfcs-r11-site
echo LFCS-11 > /var/www/lfcs-r11-site/index.html
chcon -R system_u:object_r:default_t:s0 /var/www/lfcs-r11-site
semanage fcontext -d '/var/www/lfcs-r11-site(/.*)?' >/dev/null 2>&1 || true
