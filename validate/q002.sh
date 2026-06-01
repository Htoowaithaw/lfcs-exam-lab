#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /srv/lfcs/q002/secret.txt ] || fail "secret file missing"
[ "$(stat -c '%U:%G' /srv/lfcs/q002/secret.txt)" = "root:adm" ] || fail "owner/group incorrect"
[ "$(stat -c '%a' /srv/lfcs/q002/secret.txt)" = "640" ] || fail "mode incorrect"
[ -L /opt/q002-secret ] || fail "symlink missing"
[ "$(readlink /opt/q002-secret)" = "/srv/lfcs/q002/secret.txt" ] || fail "symlink target incorrect"
echo "RESULT: PASS"
