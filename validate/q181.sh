#!/usr/bin/env bash
set -euo pipefail
if ! getent group lfcsteam3 >/dev/null; then echo "RESULT: FAIL - group missing"; exit 1; fi
if ! id -nG grpuser3 | tr ' ' '\n' | grep -qx 'lfcsteam3'; then echo "RESULT: FAIL - supplementary membership missing"; exit 1; fi
[ "$(id -g grpuser3)" != "$(getent group lfcsteam3 | cut -d: -f3)" ] || { echo "RESULT: FAIL - lfcsteam3 must be supplementary, not primary"; exit 1; }
echo "RESULT: PASS"
