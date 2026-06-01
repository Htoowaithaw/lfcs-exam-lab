#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
systemctl is-enabled lfcs-q003.service >/dev/null 2>&1 || fail "service not enabled"
systemctl is-active lfcs-q003.service >/dev/null 2>&1 || fail "service not active"
[ -f /run/lfcs-q003.ready ] || fail "ready file missing"
systemctl cat lfcs-q003.service | grep -q '^ExecStart=/usr/local/bin/lfcs-q003.sh' || fail "ExecStart not fixed"
echo "RESULT: PASS"
