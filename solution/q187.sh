#!/usr/bin/env bash
set -euo pipefail
echo 'SKEL-3' > /etc/skel/.lfcs-skel3
useradd -m skelprobe3
