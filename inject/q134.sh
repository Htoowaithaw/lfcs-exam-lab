#!/usr/bin/env bash
set -euo pipefail
userdel -r sshuser3 >/dev/null 2>&1 || true
rm -f /etc/ssh/sshd_config.d/q134.conf
systemctl restart ssh || systemctl restart sshd
