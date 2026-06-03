#!/usr/bin/env bash
set -euo pipefail
if ! getent group lfcsteam2 >/dev/null; then echo "RESULT: FAIL - group missing"; exit 1; fi
if ! id -nG grpuser2 | tr ' ' '\n' | grep -qx 'lfcsteam2'; then echo "RESULT: FAIL - supplementary membership missing"; exit 1; fi
echo "RESULT: PASS"
