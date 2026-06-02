#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

expected=$'LFCS Practice Node\nAuthorized users only\nMaintenance: Sunday 02:00 UTC'
actual="$(cat /etc/lfcs-q016/motd 2>/dev/null || true)"
[ "$actual" = "$expected" ] || fail "motd content does not exactly match"
echo "RESULT: PASS"
