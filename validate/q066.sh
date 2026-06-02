#!/usr/bin/env bash
set -euo pipefail
if ! test -s /root/lfcs-op-proc8.answer; then echo "RESULT: FAIL - check 1 failed: test -s /root/lfcs-op-proc8.answer"; exit 1; fi
if ! pid=$(cat /root/lfcs-op-proc8.answer); then echo "RESULT: FAIL - check 2 failed: pid=\$(cat /root/lfcs-op-proc8.answer)"; exit 1; fi
if ! test "$pid" = "$(cat /run/lfcs-op-proc8.pid)"; then echo "RESULT: FAIL - check 3 failed: test '\$pid' = '\$(cat /run/lfcs-op-proc8.pid)'"; exit 1; fi
if ! kill -0 "$pid"; then echo "RESULT: FAIL - check 4 failed: kill -0 '\$pid'"; exit 1; fi
if ! test "$(ps -o ni= -p "$pid" | tr -d ' ')" = "8"; then echo "RESULT: FAIL - check 5 failed: test '\$(ps -o ni= -p '\$pid' | tr -d ' ')' = '8'"; exit 1; fi
echo "RESULT: PASS"
