#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

f=/etc/lfcs-q014/app.ini
[ -f "$f" ] || fail "app.ini missing"
grep -qx '\[app\]' "$f" || fail "app header missing"
grep -qx 'environment=production' "$f" || fail "environment not production"
grep -qx 'debug=false' "$f" || fail "debug not false"
grep -qx 'workers=4' "$f" || fail "workers not 4"
grep -qx 'listen=127.0.0.1:9000' "$f" || fail "listen value not preserved"
echo "RESULT: PASS"
