#!/usr/bin/env bash
set -euo pipefail
userdel -r sudoer3 >/dev/null 2>&1 || true
rm -f /etc/sudoers.d/lfcs-sudo3
