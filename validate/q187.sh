#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
test -f /etc/skel/.lfcs-skel3 || fail 'skel file missing'
grep -Fxq 'SKEL-3' /etc/skel/.lfcs-skel3 || fail 'skel content is wrong'
probe=skelaudit3
userdel -r "$probe" >/dev/null 2>&1 || true
trap 'userdel -r "$probe" >/dev/null 2>&1 || true' EXIT
useradd -m "$probe" || fail 'could not create probe user'
test -f /home/$probe/.lfcs-skel3 || fail 'new user did not receive skel file'
grep -Fxq 'SKEL-3' /home/$probe/.lfcs-skel3 || fail 'new user received wrong skel content'
echo "RESULT: PASS"
