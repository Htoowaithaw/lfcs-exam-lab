#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/ssl/private/lfcs-op-tls1.key -a -f /etc/ssl/certs/lfcs-op-tls1.crt; then echo "RESULT: FAIL - check 1 failed: test -f /etc/ssl/private/lfcs-op-tls1.key -a -f /etc/ssl/certs/lfcs-op-tls1.crt"; exit 1; fi
if ! test "$(stat -c %a /etc/ssl/private/lfcs-op-tls1.key)" = "600"; then echo "RESULT: FAIL - check 2 failed: test '\$(stat -c %a /etc/ssl/private/lfcs-op-tls1.key)' = '600'"; exit 1; fi
if ! openssl x509 -in /etc/ssl/certs/lfcs-op-tls1.crt -noout -subject | grep -q 'CN = lfcs-op-tls1.lfcs.local\|CN=lfcs-op-tls1.lfcs.local'; then echo "RESULT: FAIL - check 3 failed: openssl x509 -in /etc/ssl/certs/lfcs-op-tls1.crt -noout -subject | grep -q 'CN = lfcs-op-tls1.lfcs.local\\|CN=lfcs-op-tls1.lfcs.local'"; exit 1; fi
if ! diff -q <(openssl rsa -in /etc/ssl/private/lfcs-op-tls1.key -pubout 2>/dev/null) <(openssl x509 -in /etc/ssl/certs/lfcs-op-tls1.crt -pubkey -noout 2>/dev/null) >/dev/null; then echo "RESULT: FAIL - check 4 failed: diff -q <(openssl rsa -in /etc/ssl/private/lfcs-op-tls1.key -pubout 2>/dev/null) <(openssl x509 -in /etc/ssl/certs/lfcs-op-tls1.crt -pubkey -noout 2>/dev/null) >/dev/null"; exit 1; fi
echo "RESULT: PASS"
