#!/usr/bin/env bash
set -euo pipefail
userdel -r sshuser1 >/dev/null 2>&1 || true
rm -f /etc/ssh/sshd_config.d/q132.conf
systemctl restart ssh || systemctl restart sshd
