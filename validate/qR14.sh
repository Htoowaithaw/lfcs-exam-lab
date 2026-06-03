#!/usr/bin/env bash
set -euo pipefail
if ! systemctl is-active --quiet firewalld; then echo "RESULT: FAIL - firewalld is not active"; exit 1; fi
if ! firewall-cmd --zone=public --list-ports | grep -qw '18402/tcp'; then echo "RESULT: FAIL - port missing from active public zone"; exit 1; fi
if ! firewall-cmd --permanent --zone=public --list-ports | grep -qw '18402/tcp'; then echo "RESULT: FAIL - port missing from permanent public zone"; exit 1; fi
echo "RESULT: PASS"
