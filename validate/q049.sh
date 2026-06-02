#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
stat -c '%U:%G:%a' /srv/ec-q049/report.txt | grep -qx 'root:adm:640' || fail "permissions or ownership incorrect"
echo "RESULT: PASS"
