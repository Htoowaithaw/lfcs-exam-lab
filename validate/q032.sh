#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q032-active.conf ] || fail "active config missing"
[ "$(cat /root/q032-active.conf)" = $'Port 22\nListenAddress 0.0.0.0' ] || fail "active config content incorrect"
echo "RESULT: PASS"
