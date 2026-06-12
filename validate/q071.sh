#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/cron.d/lfcs-op-cron5; then echo "RESULT: FAIL - check 1 failed: test -f /etc/cron.d/lfcs-op-cron5"; exit 1; fi
if ! test "$(stat -c %a /etc/cron.d/lfcs-op-cron5)" = "644"; then echo "RESULT: FAIL - check 2 failed: test '\$(stat -c %a /etc/cron.d/lfcs-op-cron5)' = '644'"; exit 1; fi
if ! grep -Eq '^\*/5 \* \* \* \* root /bin/sh -c .+/var/tmp/lfcs-op-cron5.stamp' /etc/cron.d/lfcs-op-cron5; then echo "RESULT: FAIL - check 3 failed: grep -Eq '^\\*/5 \\* \\* \\* \\* root /bin/sh -c .+/var/tmp/lfcs-op-cron5.stamp' /etc/cron.d/lfcs-op-cron5"; exit 1; fi
grep -Eq '^\*/5 \* \* \* \* root /bin/sh -c .*[[:space:]]lfcs-op-cron5-ok[[:space:]].*/var/tmp/lfcs-op-cron5\.stamp' /etc/cron.d/lfcs-op-cron5 || { echo "RESULT: FAIL - cron command does not write the required literal text"; exit 1; }
echo "RESULT: PASS"
