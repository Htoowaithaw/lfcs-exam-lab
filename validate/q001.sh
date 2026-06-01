#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /root/q001-logs.tar.gz ] || fail "archive missing"
file /root/q001-logs.tar.gz | grep -qi 'gzip compressed' || fail "archive is not gzip"
mapfile -t names < <(tar -tzf /root/q001-logs.tar.gz | sort)
printf '%s\n' "${names[@]}" | grep -qx 'app/app.log' || fail "app/app.log missing"
printf '%s\n' "${names[@]}" | grep -qx 'db/db.log' || fail "db/db.log missing"
printf '%s\n' "${names[@]}" | grep -q 'readme.txt' && fail "non-log file included"
echo "RESULT: PASS"
