#!/usr/bin/env bash
set -euo pipefail
if ! getent group lfcsteam2 >/dev/null; then echo "RESULT: FAIL - group missing"; exit 1; fi
if ! id -nG grpuser2 | tr ' ' '\n' | grep -qx 'lfcsteam2'; then echo "RESULT: FAIL - supplementary membership missing"; exit 1; fi
[ "$(id -g grpuser2)" != "$(getent group lfcsteam2 | cut -d: -f3)" ] || { echo "RESULT: FAIL - lfcsteam2 must be supplementary, not primary"; exit 1; }
echo "RESULT: PASS"
