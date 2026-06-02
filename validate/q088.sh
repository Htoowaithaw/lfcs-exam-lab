#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/apparmor.d/usr.local.bin.lfcs-op-aa2; then echo "RESULT: FAIL - check 1 failed: test -f /etc/apparmor.d/usr.local.bin.lfcs-op-aa2"; exit 1; fi
if ! apparmor_parser -Q /etc/apparmor.d/usr.local.bin.lfcs-op-aa2 >/dev/null 2>&1; then echo "RESULT: FAIL - check 2 failed: apparmor_parser -Q /etc/apparmor.d/usr.local.bin.lfcs-op-aa2 >/dev/null 2>&1"; exit 1; fi
if ! aa-status 2>/dev/null | grep -Fq '/usr/local/bin/lfcs-op-aa2'; then echo "RESULT: FAIL - check 3 failed: aa-status 2>/dev/null | grep -Fq '/usr/local/bin/lfcs-op-aa2'"; exit 1; fi
echo "RESULT: PASS"
