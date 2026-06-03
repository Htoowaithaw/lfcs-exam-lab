#!/usr/bin/env bash
set -euo pipefail
echo 'SKEL-2' > /etc/skel/.lfcs-skel2
useradd -m skelprobe2
