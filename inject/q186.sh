#!/usr/bin/env bash
set -euo pipefail
userdel -r skelprobe2 >/dev/null 2>&1 || true
rm -f /etc/skel/.lfcs-skel2
