#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

[ -f /srv/ec-q020/mirror/app.conf ] || fail "app.conf missing"
[ -f /srv/ec-q020/mirror/sub/db.conf ] || fail "sub/db.conf missing"
[ ! -e /srv/ec-q020/mirror/cache.tmp ] || fail "cache.tmp was copied"
[ ! -e /srv/ec-q020/mirror/stale.txt ] || fail "stale file was not deleted"
echo "RESULT: PASS"
