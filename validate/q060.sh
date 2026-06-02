#!/usr/bin/env bash
set -euo pipefail
if ! systemctl is-enabled --quiet lfcs-op-svc2.service; then echo "RESULT: FAIL - check 1 failed: systemctl is-enabled --quiet lfcs-op-svc2.service"; exit 1; fi
if ! systemctl is-active --quiet lfcs-op-svc2.service; then echo "RESULT: FAIL - check 2 failed: systemctl is-active --quiet lfcs-op-svc2.service"; exit 1; fi
if ! grep -q '^ExecStart=/usr/local/bin/lfcs-op-svc2.sh$' /etc/systemd/system/lfcs-op-svc2.service; then echo "RESULT: FAIL - check 3 failed: grep -q '^ExecStart=/usr/local/bin/lfcs-op-svc2.sh\$' /etc/systemd/system/lfcs-op-svc2.service"; exit 1; fi
if ! test -s /run/lfcs-op-svc2.ready; then echo "RESULT: FAIL - check 4 failed: test -s /run/lfcs-op-svc2.ready"; exit 1; fi
echo "RESULT: PASS"
