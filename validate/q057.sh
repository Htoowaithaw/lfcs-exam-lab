#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
git -C /var/tmp/ec-q057/repo log -1 --pretty=%s | grep -qx 'update app config' || fail "commit message incorrect"
[ "$(git -C /var/tmp/ec-q057/repo status --porcelain)" = "" ] || fail "working tree not clean"
echo "RESULT: PASS"
