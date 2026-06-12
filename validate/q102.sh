#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/ssl/private/lfcs-op-tls3.key -a -f /etc/ssl/certs/lfcs-op-tls3.crt; then echo "RESULT: FAIL - check 1 failed: test -f /etc/ssl/private/lfcs-op-tls3.key -a -f /etc/ssl/certs/lfcs-op-tls3.crt"; exit 1; fi
if ! test "$(stat -c %a /etc/ssl/private/lfcs-op-tls3.key)" = "600"; then echo "RESULT: FAIL - check 2 failed: test '\$(stat -c %a /etc/ssl/private/lfcs-op-tls3.key)' = '600'"; exit 1; fi
if ! openssl x509 -in /etc/ssl/certs/lfcs-op-tls3.crt -noout -subject | grep -q 'CN = lfcs-op-tls3.lfcs.local\|CN=lfcs-op-tls3.lfcs.local'; then echo "RESULT: FAIL - check 3 failed: openssl x509 -in /etc/ssl/certs/lfcs-op-tls3.crt -noout -subject | grep -q 'CN = lfcs-op-tls3.lfcs.local\\|CN=lfcs-op-tls3.lfcs.local'"; exit 1; fi
if ! diff -q <(openssl rsa -in /etc/ssl/private/lfcs-op-tls3.key -pubout 2>/dev/null) <(openssl x509 -in /etc/ssl/certs/lfcs-op-tls3.crt -pubkey -noout 2>/dev/null) >/dev/null; then echo "RESULT: FAIL - check 4 failed: diff -q <(openssl rsa -in /etc/ssl/private/lfcs-op-tls3.key -pubout 2>/dev/null) <(openssl x509 -in /etc/ssl/certs/lfcs-op-tls3.crt -pubkey -noout 2>/dev/null) >/dev/null"; exit 1; fi
openssl pkey -in /etc/ssl/private/lfcs-op-tls3.key -text -noout 2>/dev/null | grep -q 'Private-Key: (2048 bit' || { echo "RESULT: FAIL - RSA key is not 2048 bits"; exit 1; }
[ "$(openssl x509 -in /etc/ssl/certs/lfcs-op-tls3.crt -noout -subject | sed 's/^subject=//')" = "$(openssl x509 -in /etc/ssl/certs/lfcs-op-tls3.crt -noout -issuer | sed 's/^issuer=//')" ] || { echo "RESULT: FAIL - certificate is not self-signed"; exit 1; }
echo "RESULT: PASS"
