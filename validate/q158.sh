#!/usr/bin/env bash
set -euo pipefail
if ! findmnt -no OPTIONS /mnt/lfcs-opt3 | grep -qw 'noexec'; then echo "RESULT: FAIL - mount option is not active"; exit 1; fi
if ! grep -q 'noexec' /etc/fstab; then echo "RESULT: FAIL - mount option is not persistent"; exit 1; fi
if ! mount -a; then echo "RESULT: FAIL - mount -a failed"; exit 1; fi
echo "RESULT: PASS"
