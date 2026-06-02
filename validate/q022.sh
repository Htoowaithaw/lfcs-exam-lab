#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

[ -f /var/tmp/ec-q022/audit.log ] || fail "original audit.log not preserved"
[ -f /root/q022-audit.log.gz ] || fail "compressed file missing"
diff -u /var/tmp/ec-q022/audit.log <(gzip -dc /root/q022-audit.log.gz) >/dev/null || fail "compressed content incorrect"
echo "RESULT: PASS"
