#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
systemctl is-active firewalld >/dev/null || fail "firewalld is not active"
firewall-cmd --reload >/dev/null
firewall-cmd --zone=public --list-ports | tr ' ' '\n' | grep -qx '8443/tcp' || fail "8443/tcp not open after reload"
firewall-cmd --permanent --zone=public --list-ports | tr ' ' '\n' | grep -qx '8443/tcp' || fail "8443/tcp not permanent"
echo "RESULT: PASS"
