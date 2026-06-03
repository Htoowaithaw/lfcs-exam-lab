#!/usr/bin/env bash
set -euo pipefail
userdel -r limituser3 >/dev/null 2>&1 || true
rm -f /etc/security/limits.d/lfcs-limit3.conf
