#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/apparmor.d/usr.local.bin.lfcs-op-aa3; then echo "RESULT: FAIL - check 1 failed: test -f /etc/apparmor.d/usr.local.bin.lfcs-op-aa3"; exit 1; fi
if ! apparmor_parser -Q /etc/apparmor.d/usr.local.bin.lfcs-op-aa3 >/dev/null 2>&1; then echo "RESULT: FAIL - check 2 failed: apparmor_parser -Q /etc/apparmor.d/usr.local.bin.lfcs-op-aa3 >/dev/null 2>&1"; exit 1; fi
if ! aa-status 2>/dev/null | grep -Fq '/usr/local/bin/lfcs-op-aa3'; then echo "RESULT: FAIL - check 3 failed: aa-status 2>/dev/null | grep -Fq '/usr/local/bin/lfcs-op-aa3'"; exit 1; fi
aa-status 2>/dev/null | awk '/profiles are in enforce mode/ {inside=1; next} /profiles are in complain mode/ {inside=0} inside && $1=="/usr/local/bin/lfcs-op-aa3" {found=1} END {exit !found}' || { echo "RESULT: FAIL - AppArmor profile is not in enforce mode"; exit 1; }
echo "RESULT: PASS"
