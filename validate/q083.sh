#!/usr/bin/env bash
set -euo pipefail
if ! test -s /root/lfcs-op-mon12.txt; then echo "RESULT: FAIL - check 1 failed: test -s /root/lfcs-op-mon12.txt"; exit 1; fi
if ! grep -Eq 'PID|COMMAND' /root/lfcs-op-mon12.txt; then echo "RESULT: FAIL - check 2 failed: grep -Eq 'PID|COMMAND' /root/lfcs-op-mon12.txt"; exit 1; fi
if ! grep -q 'procs' /root/lfcs-op-mon12.txt; then echo "RESULT: FAIL - check 3 failed: grep -q 'procs' /root/lfcs-op-mon12.txt"; exit 1; fi
if ! grep -q 'load average' /root/lfcs-op-mon12.txt; then echo "RESULT: FAIL - check 4 failed: grep -q 'load average' /root/lfcs-op-mon12.txt"; exit 1; fi
echo "RESULT: PASS"
