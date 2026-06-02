#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
stat -c '%U:%G:%a' /usr/local/bin/q052-idcopy | grep -qx 'root:root:4755' || fail "permissions or ownership incorrect"
echo "RESULT: PASS"
