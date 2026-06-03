#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/profile.d/lfcs-profile3.sh; then echo "RESULT: FAIL - profile script missing"; exit 1; fi
if ! bash -lc 'test "$LFCS_PROFILE_3" = enabled3'; then echo "RESULT: FAIL - login shell does not receive variable"; exit 1; fi
echo "RESULT: PASS"
