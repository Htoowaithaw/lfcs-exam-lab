#!/usr/bin/env bash
set -euo pipefail
if ! test "$(getenforce)" = "Enforcing"; then echo "RESULT: FAIL - check 1 failed: test '\$(getenforce)' = 'Enforcing'"; exit 1; fi
if ! getsebool httpd_can_sendmail | grep -q -- '--> on'; then echo "RESULT: FAIL - check 2 failed: getsebool httpd_can_sendmail | grep -q -- '--> on'"; exit 1; fi
echo "RESULT: PASS"
