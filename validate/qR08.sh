#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ "$(getenforce)" = 'Enforcing' ] || fail 'SELinux is not enforcing'
getsebool nis_enabled | grep -q -- '--> on' || fail 'boolean is not on'
boolean_line="$(semanage boolean -l | awk '$1=="nis_enabled"{line=$0} END{print line}')"
[[ "$boolean_line" =~ ^nis_enabled[[:space:]]+\(on[[:space:]]*,[[:space:]]*on\) ]] || fail 'boolean is not persistent'
echo "RESULT: PASS"
