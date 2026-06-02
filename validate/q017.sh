#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

f=/etc/ec-q017/app.conf
grep -qx 'port=9443' "$f" || fail "port not patched"
grep -qx 'tls=enabled' "$f" || fail "tls not patched"
grep -qx 'log_level=info' "$f" || fail "log level not patched"
echo "RESULT: PASS"
