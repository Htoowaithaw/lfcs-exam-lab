#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

f=/root/q018-types.txt
[ -f "$f" ] || fail "types file missing"
expected=$'conf.d:directory\npayload.gz:gzip\nreadme.txt:text'
[ "$(cat "$f")" = "$expected" ] || fail "types file content incorrect"
echo "RESULT: PASS"
