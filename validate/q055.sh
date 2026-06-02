#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
getfacl -p /srv/ec-q055/secret.txt | grep -qx 'user:nobody:r--' && [ "$(stat -c %a /srv/ec-q055/secret.txt)" = "640" ] || fail "ACL or attribute requirement not met"
echo "RESULT: PASS"
