#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ "$(getenforce)" = 'Enforcing' ] || fail 'SELinux is not enforcing'
getsebool httpd_can_sendmail | grep -q -- '--> on' || fail 'boolean is not on'
boolean_line="$(semanage boolean -l | awk '$1=="httpd_can_sendmail"{line=$0} END{print line}')"
[[ "$boolean_line" =~ ^httpd_can_sendmail[[:space:]]+\(on[[:space:]]*,[[:space:]]*on\) ]] || fail 'boolean is not persistent'
echo "RESULT: PASS"
