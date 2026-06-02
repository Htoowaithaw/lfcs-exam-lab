#!/usr/bin/env bash
set -euo pipefail
rm -rf /opt/ec-q012 /var/tmp/ec-q012
mkdir -p /var/tmp/ec-q012
printf '2026.06\n' > /var/tmp/ec-q012/VERSION
