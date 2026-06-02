#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

f=/etc/lfcs-q015/hosts.extra
grep -Eq '^10\.20\.30\.40[[:space:]]+api\.lfcs\.local$' "$f" || fail "api mapping incorrect"
grep -Eq '^10\.20\.30\.41[[:space:]]+db\.lfcs\.local$' "$f" || fail "db mapping missing"
[ "$(awk '$2=="old-api.lfcs.local"{c++} END{print c+0}' "$f")" -eq 1 ] || fail "old-api must appear exactly once"
echo "RESULT: PASS"
