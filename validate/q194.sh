#!/usr/bin/env bash
set -euo pipefail
if ! getent passwd sudoer4 >/dev/null; then echo "RESULT: FAIL - sudo user missing"; exit 1; fi
if ! visudo -cf /etc/sudoers.d/lfcs-sudo4 >/dev/null; then echo "RESULT: FAIL - sudoers file syntax invalid"; exit 1; fi
if ! sudo -l -U sudoer4 | grep -Fq 'NOPASSWD: /usr/bin/journalctl'; then echo "RESULT: FAIL - sudo privilege missing or too different"; exit 1; fi
echo "RESULT: PASS"
