#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/cron.d/lfcs-op-cron5; then echo "RESULT: FAIL - check 1 failed: test -f /etc/cron.d/lfcs-op-cron5"; exit 1; fi
if ! test "$(stat -c %a /etc/cron.d/lfcs-op-cron5)" = "644"; then echo "RESULT: FAIL - check 2 failed: test '\$(stat -c %a /etc/cron.d/lfcs-op-cron5)' = '644'"; exit 1; fi
grep -Eq '^\*/5[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+root[[:space:]]+.*lfcs-op-cron5-ok.*/var/tmp/lfcs-op-cron5\.stamp' /etc/cron.d/lfcs-op-cron5 || { echo "RESULT: FAIL - root cron entry must run every 5 minutes and write lfcs-op-cron5-ok to /var/tmp/lfcs-op-cron5.stamp"; exit 1; }
echo "RESULT: PASS"
