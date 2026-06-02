#!/usr/bin/env bash
set -euo pipefail
if ! test "$(sysctl -n kernel.dmesg_restrict)" = "1"; then echo "RESULT: FAIL - check 1 failed: test '\$(sysctl -n kernel.dmesg_restrict)' = '1'"; exit 1; fi
if ! test -f /etc/sysctl.d/lfcs-op-sysctl3.conf; then echo "RESULT: FAIL - check 2 failed: test -f /etc/sysctl.d/lfcs-op-sysctl3.conf"; exit 1; fi
if ! grep -Eq '^kernel\.dmesg_restrict[[:space:]]*=[[:space:]]*1$' /etc/sysctl.d/lfcs-op-sysctl3.conf; then echo "RESULT: FAIL - check 3 failed: grep -Eq '^kernel\\.dmesg_restrict[[:space:]]*=[[:space:]]*1\$' /etc/sysctl.d/lfcs-op-sysctl3.conf"; exit 1; fi
echo "RESULT: PASS"
