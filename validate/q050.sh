#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
stat -c '%U:%G:%a' /srv/ec-q050/run.sh | grep -qx 'root:staff:750' || fail "permissions or ownership incorrect"
echo "RESULT: PASS"
