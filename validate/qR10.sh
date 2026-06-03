#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -d /var/www/lfcs-r10-site ] || fail 'site directory missing'
[ -f /var/www/lfcs-r10-site/index.html ] || fail 'index file missing'
[ "$(stat -c '%C' /var/www/lfcs-r10-site | awk -F: '{print $3}')" = 'httpd_sys_content_t' ] || fail 'directory context is not httpd_sys_content_t'
[ "$(stat -c '%C' /var/www/lfcs-r10-site/index.html | awk -F: '{print $3}')" = 'httpd_sys_content_t' ] || fail 'file context is not httpd_sys_content_t'
semanage fcontext -l | awk '$1 == "/var/www/lfcs-r10-site(/.*)?" && $NF ~ /:httpd_sys_content_t:/ { found=1 } END { exit !found }' || fail 'persistent fcontext rule missing for site files'
echo "RESULT: PASS"
