#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/rsyslog.d/lfcs-op-log2.conf; then echo "RESULT: FAIL - check 1 failed: test -f /etc/rsyslog.d/lfcs-op-log2.conf"; exit 1; fi
if ! rsyslogd -N1 >/dev/null 2>&1; then echo "RESULT: FAIL - check 2 failed: rsyslogd -N1 >/dev/null 2>&1"; exit 1; fi
if ! test -s /var/log/lfcs-op-log2.log; then echo "RESULT: FAIL - check 3 failed: test -s /var/log/lfcs-op-log2.log"; exit 1; fi
if ! grep -q 'LFCS-2' /var/log/lfcs-op-log2.log; then echo "RESULT: FAIL - check 4 failed: grep -q 'LFCS-2' /var/log/lfcs-op-log2.log"; exit 1; fi
echo "RESULT: PASS"
