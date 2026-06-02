#!/usr/bin/env bash
set -euo pipefail
if ! test "$(sysctl -n net.ipv4.ip_forward)" = "1"; then echo "RESULT: FAIL - check 1 failed: test '\$(sysctl -n net.ipv4.ip_forward)' = '1'"; exit 1; fi
if ! test -f /etc/sysctl.d/lfcs-op-sysctl1.conf; then echo "RESULT: FAIL - check 2 failed: test -f /etc/sysctl.d/lfcs-op-sysctl1.conf"; exit 1; fi
if ! grep -Eq '^net\.ipv4\.ip_forward[[:space:]]*=[[:space:]]*1$' /etc/sysctl.d/lfcs-op-sysctl1.conf; then echo "RESULT: FAIL - check 3 failed: grep -Eq '^net\\.ipv4\\.ip_forward[[:space:]]*=[[:space:]]*1\$' /etc/sysctl.d/lfcs-op-sysctl1.conf"; exit 1; fi
echo "RESULT: PASS"
