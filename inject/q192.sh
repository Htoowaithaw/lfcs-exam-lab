#!/usr/bin/env bash
set -euo pipefail
userdel -r sudoer2 >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/lfcs-sudo2
