#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/skel/.lfcs-skel2; then echo "RESULT: FAIL - skel file missing"; exit 1; fi
if ! test -f /home/skelprobe2/.lfcs-skel2; then echo "RESULT: FAIL - probe user did not receive skel file"; exit 1; fi
if ! grep -q 'SKEL-2' /home/skelprobe2/.lfcs-skel2; then echo "RESULT: FAIL - probe skel content wrong"; exit 1; fi
echo "RESULT: PASS"
