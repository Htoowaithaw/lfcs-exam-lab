#!/usr/bin/env bash
set -euo pipefail
if ! getent passwd sshuser4 >/dev/null; then echo "RESULT: FAIL - ssh test user missing"; exit 1; fi
if ! test -s /home/sshuser4/.ssh/authorized_keys; then echo "RESULT: FAIL - authorized_keys missing"; exit 1; fi
if ! sshd -T | awk '$1 == "passwordauthentication" && $2 == "no" { found=1 } END { exit !found }'; then echo "RESULT: FAIL - password auth is not disabled effectively"; exit 1; fi
if ! sshd -T | awk '$1 == "pubkeyauthentication" && $2 == "yes" { found=1 } END { exit !found }'; then echo "RESULT: FAIL - pubkey auth is not enabled effectively"; exit 1; fi
if ! (systemctl is-active --quiet ssh || systemctl is-active --quiet sshd); then echo "RESULT: FAIL - ssh service is not active"; exit 1; fi
echo "RESULT: PASS"
