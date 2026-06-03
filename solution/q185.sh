#!/usr/bin/env bash
set -euo pipefail
echo 'SKEL-1' > /etc/skel/.lfcs-skel1
useradd -m skelprobe1
