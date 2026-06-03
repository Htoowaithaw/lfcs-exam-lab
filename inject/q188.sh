#!/usr/bin/env bash
set -euo pipefail
userdel -r limituser1 >/dev/null 2>&1 || true
rm -f /etc/security/limits.d/lfcs-limit1.conf
