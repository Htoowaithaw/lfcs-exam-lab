#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/cron.d/lfcs-op-cron15; then echo "RESULT: FAIL - check 1 failed: test -f /etc/cron.d/lfcs-op-cron15"; exit 1; fi
if ! test "$(stat -c %a /etc/cron.d/lfcs-op-cron15)" = "644"; then echo "RESULT: FAIL - check 2 failed: test '\$(stat -c %a /etc/cron.d/lfcs-op-cron15)' = '644'"; exit 1; fi
if ! grep -Eq '^\*/15 \* \* \* \* root /bin/sh -c .+/var/tmp/lfcs-op-cron15.stamp' /etc/cron.d/lfcs-op-cron15; then echo "RESULT: FAIL - check 3 failed: grep -Eq '^\\*/15 \\* \\* \\* \\* root /bin/sh -c .+/var/tmp/lfcs-op-cron15.stamp' /etc/cron.d/lfcs-op-cron15"; exit 1; fi
grep -Eq '^\*/15 \* \* \* \* root /bin/sh -c .*[[:space:]]lfcs-op-cron15-ok[[:space:]].*/var/tmp/lfcs-op-cron15\.stamp' /etc/cron.d/lfcs-op-cron15 || { echo "RESULT: FAIL - cron command does not write the required literal text"; exit 1; }
echo "RESULT: PASS"
