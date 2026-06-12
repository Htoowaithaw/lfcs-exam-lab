#!/usr/bin/env bash
set -euo pipefail
if ! test -s /root/lfcs-op-mon6.txt; then echo "RESULT: FAIL - check 1 failed: test -s /root/lfcs-op-mon6.txt"; exit 1; fi
if ! grep -Eq 'PID|COMMAND' /root/lfcs-op-mon6.txt; then echo "RESULT: FAIL - check 2 failed: grep -Eq 'PID|COMMAND' /root/lfcs-op-mon6.txt"; exit 1; fi
if ! grep -q 'procs' /root/lfcs-op-mon6.txt; then echo "RESULT: FAIL - check 3 failed: grep -q 'procs' /root/lfcs-op-mon6.txt"; exit 1; fi
if ! grep -q 'load average' /root/lfcs-op-mon6.txt; then echo "RESULT: FAIL - check 4 failed: grep -q 'load average' /root/lfcs-op-mon6.txt"; exit 1; fi
grep -Eq '(^|[[:space:]])PID([[:space:]]|$)' /root/lfcs-op-mon6.txt || { echo "RESULT: FAIL - ps PID header missing"; exit 1; }
awk '$1 ~ /^[0-9]+$/ {found=1} END {exit !found}' /root/lfcs-op-mon6.txt || { echo "RESULT: FAIL - process snapshot has no process row"; exit 1; }
awk '$1 ~ /^[0-9]+$/ && NF >= 10 {found=1} END {exit !found}' /root/lfcs-op-mon6.txt || { echo "RESULT: FAIL - vmstat snapshot has no data row"; exit 1; }
echo "RESULT: PASS"
