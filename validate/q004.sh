#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
crontab -l 2>/dev/null | grep -Eq '^\*/5[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]].*LFCS_Q004.*>>[[:space:]]*/var/log/lfcs-q004.log' || fail "root cron entry missing or incorrect"
echo "RESULT: PASS"
