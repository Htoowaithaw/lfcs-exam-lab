#!/usr/bin/env bash
set -euo pipefail
if ! getent group lfcsteam1 >/dev/null; then echo "RESULT: FAIL - group missing"; exit 1; fi
if ! id -nG grpuser1 | tr ' ' '\n' | grep -qx 'lfcsteam1'; then echo "RESULT: FAIL - supplementary membership missing"; exit 1; fi
[ "$(id -g grpuser1)" != "$(getent group lfcsteam1 | cut -d: -f3)" ] || { echo "RESULT: FAIL - lfcsteam1 must be supplementary, not primary"; exit 1; }
echo "RESULT: PASS"
