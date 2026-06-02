#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
stat -c '%U:%G:%a' /srv/ec-q054/uploads | grep -qx 'root:root:1777' || fail "permissions or ownership incorrect"
echo "RESULT: PASS"
