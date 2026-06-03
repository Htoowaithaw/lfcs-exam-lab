#!/usr/bin/env bash
set -euo pipefail
if ! test -s /root/lfcs-storage-perf3.txt; then echo "RESULT: FAIL - report file missing"; exit 1; fi
if ! grep -q '^LSBLK' /root/lfcs-storage-perf3.txt; then echo "RESULT: FAIL - lsblk section missing"; exit 1; fi
if ! grep -q '^DF' /root/lfcs-storage-perf3.txt; then echo "RESULT: FAIL - df section missing"; exit 1; fi
if ! grep -q '^READAHEAD' /root/lfcs-storage-perf3.txt; then echo "RESULT: FAIL - read-ahead section missing"; exit 1; fi
echo "RESULT: PASS"
