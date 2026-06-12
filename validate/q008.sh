#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /swap-lfcs ] || fail "swap file missing"
[ "$(stat -c '%a' /swap-lfcs)" = "600" ] || fail "swap file mode must be 600"
swapon --show=NAME --noheadings | grep -qx '/swap-lfcs' || fail "swap not active"
grep -Eq '^[^#]*/swap-lfcs[[:space:]]+none[[:space:]]+swap' /etc/fstab || fail "fstab swap entry missing"
[ "$(stat -c %s /swap-lfcs)" -eq 134217728 ] || fail "swap file size must be exactly 128 MiB"
echo "RESULT: PASS"
