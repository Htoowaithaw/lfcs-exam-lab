#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
getsebool httpd_can_network_connect | grep -q -- '--> on' || fail "boolean is not on"
semanage boolean -l | awk '$1=="httpd_can_network_connect"{print $3}' | grep -qx 'on' || fail "boolean is not persistent"
echo "RESULT: PASS"
