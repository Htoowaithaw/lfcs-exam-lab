#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
getent passwd sudoer4 >/dev/null || fail 'sudo user missing'
visudo -cf /etc/sudoers.d/lfcs-sudo4 >/dev/null || fail 'sudoers file syntax invalid'
awk 'NF && $1 !~ /^#/ { print }' /etc/sudoers.d/lfcs-sudo4 | grep -Fxq 'sudoer4 ALL=(root) NOPASSWD: /usr/bin/journalctl' || fail 'sudoers file does not contain exact requested rule'
[ "$(awk 'NF && $1 !~ /^#/ { count++ } END { print count+0 }' /etc/sudoers.d/lfcs-sudo4)" = '1' ] || fail 'sudoers file contains extra active rules'
sudo -l -U sudoer4 | awk '/^[[:space:]]*\(/ { sub(/^[[:space:]]+/, ""); print }' > /tmp/194-sudo-list
grep -Fxq '(root) NOPASSWD: /usr/bin/journalctl' /tmp/194-sudo-list || fail 'sudo privilege missing or too different'
[ "$(wc -l < /tmp/194-sudo-list)" = '1' ] || fail 'sudo user has broader or extra privileges'
echo "RESULT: PASS"
