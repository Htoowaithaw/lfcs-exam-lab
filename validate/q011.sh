#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

base=/srv/lfcs/ec-layout
[ -d "$base/bin" ] || fail "bin directory missing"
[ -d "$base/conf" ] || fail "conf directory missing"
[ -d "$base/logs/archive" ] || fail "logs/archive directory missing"
[ -f "$base/conf/config.ini" ] || fail "config.ini missing"
grep -qx 'PORT=8080' "$base/conf/config.ini" || fail "config content missing"
[ ! -e /var/tmp/ec-q011/app.conf ] || fail "source app.conf was not moved"
[ -x "$base/bin/run-check" ] || fail "run-check missing or not executable"
[ -L "$base/latest-log" ] || fail "latest-log symlink missing"
[ "$(readlink "$base/latest-log")" = "logs/current.log" ] || fail "latest-log target is not relative logs/current.log"
echo "RESULT: PASS"
