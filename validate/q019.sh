#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

f=/root/q019-change.diff
[ -f "$f" ] || fail "diff file missing"
grep -q '^--- .*original.txt' "$f" || fail "original header missing"
grep -q '^+++ .*updated.txt' "$f" || fail "updated header missing"
grep -q '^-beta=old' "$f" || fail "removed beta line missing"
grep -q '^+beta=new' "$f" || fail "added beta line missing"
grep -q '^+delta=4' "$f" || fail "delta addition missing"
echo "RESULT: PASS"
