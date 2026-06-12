#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/profile.d/lfcs-op-sec1.sh; then echo "RESULT: FAIL - check 1 failed: test -f /etc/profile.d/lfcs-op-sec1.sh"; exit 1; fi
if ! grep -q '^umask 027$' /etc/profile.d/lfcs-op-sec1.sh; then echo "RESULT: FAIL - check 2 failed: grep -q '^umask 027\$' /etc/profile.d/lfcs-op-sec1.sh"; exit 1; fi
if ! grep -q '^TMOUT=601$' /etc/profile.d/lfcs-op-sec1.sh; then echo "RESULT: FAIL - check 3 failed: grep -q '^TMOUT=601\$' /etc/profile.d/lfcs-op-sec1.sh"; exit 1; fi
if ! test "$(stat -c %a /etc/profile.d/lfcs-op-sec1.sh)" = "644"; then echo "RESULT: FAIL - check 4 failed: test '\$(stat -c %a /etc/profile.d/lfcs-op-sec1.sh)' = '644'"; exit 1; fi
bash -lc 'test "$(umask)" = 0027 && test "$TMOUT" = 601' || { echo "RESULT: FAIL - login shell does not receive the requested umask and TMOUT"; exit 1; }
echo "RESULT: PASS"
