#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

s=/usr/local/bin/q023-backup.sh
[ -x "$s" ] || fail "script missing or not executable"
rm -f /root/q023-backup.tar.gz
"$s" || fail "script execution failed"
[ -f /root/q023-backup.tar.gz ] || fail "backup archive missing"
tar -tzf /root/q023-backup.tar.gz | grep -qx './one.txt\|one.txt' || fail "one.txt not archived"
tar -tzf /root/q023-backup.tar.gz | grep -qx './two.txt\|two.txt' || fail "two.txt not archived"
echo "RESULT: PASS"
