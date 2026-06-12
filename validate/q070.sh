#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/rsyslog.d/lfcs-op-log4.conf; then echo "RESULT: FAIL - check 1 failed: test -f /etc/rsyslog.d/lfcs-op-log4.conf"; exit 1; fi
if ! rsyslogd -N1 >/dev/null 2>&1; then echo "RESULT: FAIL - check 2 failed: rsyslogd -N1 >/dev/null 2>&1"; exit 1; fi
if ! test -s /var/log/lfcs-op-log4.log; then echo "RESULT: FAIL - check 3 failed: test -s /var/log/lfcs-op-log4.log"; exit 1; fi
if ! grep -q 'LFCS-4' /var/log/lfcs-op-log4.log; then echo "RESULT: FAIL - check 4 failed: grep -q 'LFCS-4' /var/log/lfcs-op-log4.log"; exit 1; fi
systemctl is-active --quiet rsyslog || { echo "RESULT: FAIL - rsyslog is not active"; exit 1; }
marker="LFCS-4-VALIDATE-$$"
logger -t lfcs-op-log4-tag "$marker"
for _ in {1..20}; do grep -Fq "$marker" /var/log/lfcs-op-log4.log 2>/dev/null && break; sleep 0.25; done
grep -Fq "$marker" /var/log/lfcs-op-log4.log || { echo "RESULT: FAIL - live rsyslog routing is not working"; exit 1; }
echo "RESULT: PASS"
