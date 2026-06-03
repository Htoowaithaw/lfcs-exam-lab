#!/usr/bin/env bash
set -euo pipefail
userdel -r sshuser5 >/dev/null 2>&1 || true
rm -f /etc/ssh/sshd_config.d/q136.conf
systemctl restart ssh || systemctl restart sshd
