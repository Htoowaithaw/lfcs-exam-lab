#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
getent group webops >/dev/null || fail "webops group missing"
id alice >/dev/null 2>&1 || fail "alice missing"
id bob >/dev/null 2>&1 || fail "bob missing"
id -nG alice | tr ' ' '\n' | grep -qx 'webops' || fail "alice not in webops"
id -nG bob | tr ' ' '\n' | grep -qx 'webops' || fail "bob not in webops"
[ -d /srv/web ] || fail "/srv/web missing"
[ "$(stat -c '%U:%G' /srv/web)" = "root:webops" ] || fail "/srv/web ownership incorrect"
[ "$(stat -c '%a' /srv/web)" = "2775" ] || fail "/srv/web mode incorrect"
echo "RESULT: PASS"
