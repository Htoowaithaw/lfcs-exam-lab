#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /var/www/html/lfcs-r01/index.html ] || fail "web file missing"
actual="$(stat -c '%C' /var/www/html/lfcs-r01/index.html | awk -F: '{print $3}')"
expected="$(matchpathcon /var/www/html/lfcs-r01/index.html | awk '{print $2}' | awk -F: '{print $3}')"
[ "$actual" = "httpd_sys_content_t" ] || fail "actual type is $actual"
[ "$actual" = "$expected" ] || fail "context does not match policy default"
echo "RESULT: PASS"
