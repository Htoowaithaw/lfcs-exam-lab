#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ "$(getenforce)" = 'Enforcing' ] || fail 'SELinux is not enforcing'
getsebool virt_use_nfs | grep -q -- '--> on' || fail 'boolean is not on'
boolean_line="$(semanage boolean -l | awk '$1=="virt_use_nfs"{line=$0} END{print line}')"
[[ "$boolean_line" =~ ^virt_use_nfs[[:space:]]+\(on[[:space:]]*,[[:space:]]*on\) ]] || fail 'boolean is not persistent'
echo "RESULT: PASS"
