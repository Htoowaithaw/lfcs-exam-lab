#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

for d in docs bin data; do [ -d "/srv/ec-q013/$d" ] || fail "$d directory missing"; done
[ -f /srv/ec-q013/docs/readme.md ] || fail "markdown file not moved"
[ -f /srv/ec-q013/data/report.csv ] || fail "csv file not moved"
[ -x /srv/ec-q013/bin/deploy.sh ] || fail "deploy.sh missing or not executable"
[ -x /srv/ec-q013/bin/clean.sh ] || fail "clean.sh missing or not executable"
[ -d /var/tmp/ec-q013/incoming ] || fail "incoming directory missing"
[ "$(find /var/tmp/ec-q013/incoming -mindepth 1 -print -quit)" = "" ] || fail "incoming is not empty"
echo "RESULT: PASS"
