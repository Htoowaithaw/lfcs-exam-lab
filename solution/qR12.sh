#!/usr/bin/env bash
set -euo pipefail
semanage fcontext -a -t httpd_sys_content_t '/var/www/lfcs-r12-site(/.*)?'
restorecon -Rv /var/www/lfcs-r12-site
