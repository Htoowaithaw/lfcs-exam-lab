#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/cron.d/lfcs-op-cron10; then echo "RESULT: FAIL - check 1 failed: test -f /etc/cron.d/lfcs-op-cron10"; exit 1; fi
if ! test "$(stat -c %a /etc/cron.d/lfcs-op-cron10)" = "644"; then echo "RESULT: FAIL - check 2 failed: test '\$(stat -c %a /etc/cron.d/lfcs-op-cron10)' = '644'"; exit 1; fi
grep -Eq '^\*/10[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+\*[[:space:]]+root[[:space:]]+.*lfcs-op-cron10-ok.*/var/tmp/lfcs-op-cron10\.stamp' /etc/cron.d/lfcs-op-cron10 || { echo "RESULT: FAIL - root cron entry must run every 10 minutes and write lfcs-op-cron10-ok to /var/tmp/lfcs-op-cron10.stamp"; exit 1; }
echo "RESULT: PASS"
