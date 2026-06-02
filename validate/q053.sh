#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
stat -c '%U:%G:%a' /srv/ec-q053/team | grep -qx 'root:adm:2775' || fail "permissions or ownership incorrect"
echo "RESULT: PASS"
