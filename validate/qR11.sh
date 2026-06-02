#!/usr/bin/env bash
set -euo pipefail
if ! ls -Zd /var/www/lfcs-r11-site | grep -q 'httpd_sys_content_t'; then echo "RESULT: FAIL - check 1 failed: ls -Zd /var/www/lfcs-r11-site | grep -q 'httpd_sys_content_t'"; exit 1; fi
if ! ls -Z /var/www/lfcs-r11-site/index.html | grep -q 'httpd_sys_content_t'; then echo "RESULT: FAIL - check 2 failed: ls -Z /var/www/lfcs-r11-site/index.html | grep -q 'httpd_sys_content_t'"; exit 1; fi
echo "RESULT: PASS"
