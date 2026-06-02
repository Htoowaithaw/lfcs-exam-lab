#!/usr/bin/env bash
set -euo pipefail
if ! systemctl is-enabled --quiet lfcs-op-svc1.service; then echo "RESULT: FAIL - check 1 failed: systemctl is-enabled --quiet lfcs-op-svc1.service"; exit 1; fi
if ! systemctl is-active --quiet lfcs-op-svc1.service; then echo "RESULT: FAIL - check 2 failed: systemctl is-active --quiet lfcs-op-svc1.service"; exit 1; fi
if ! grep -q '^ExecStart=/usr/local/bin/lfcs-op-svc1.sh$' /etc/systemd/system/lfcs-op-svc1.service; then echo "RESULT: FAIL - check 3 failed: grep -q '^ExecStart=/usr/local/bin/lfcs-op-svc1.sh\$' /etc/systemd/system/lfcs-op-svc1.service"; exit 1; fi
if ! test -s /run/lfcs-op-svc1.ready; then echo "RESULT: FAIL - check 4 failed: test -s /run/lfcs-op-svc1.ready"; exit 1; fi
echo "RESULT: PASS"
