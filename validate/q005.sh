#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
getent hosts repo.lfcs.local | awk '{print $1}' | grep -qx '10.10.10.50' || fail "repo.lfcs.local does not resolve correctly"
grep -Eq '^[[:space:]]*10\.10\.10\.50[[:space:]]+.*repo\.lfcs\.local' /etc/hosts || fail "/etc/hosts entry missing"
echo "RESULT: PASS"
