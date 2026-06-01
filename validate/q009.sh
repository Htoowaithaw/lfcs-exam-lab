#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
id examuser >/dev/null 2>&1 || fail "examuser missing"
[ "$(id -u examuser)" = "2401" ] || fail "UID incorrect"
[ "$(getent passwd examuser | cut -d: -f7)" = "/bin/bash" ] || fail "shell incorrect"
id -nG examuser | tr ' ' '\n' | grep -qx 'lfcsgrp' || fail "secondary group missing"
chage -l examuser | grep -q 'Account expires.*Dec 31, 2030' || fail "expiry incorrect"
echo "RESULT: PASS"
