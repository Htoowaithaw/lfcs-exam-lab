#!/usr/bin/env bash
set -euo pipefail
mkdir -p /var/www/lfcs-r12-site
echo LFCS-12 > /var/www/lfcs-r12-site/index.html
chcon -R system_u:object_r:default_t:s0 /var/www/lfcs-r12-site
semanage fcontext -d '/var/www/lfcs-r12-site(/.*)?' >/dev/null 2>&1 || true
