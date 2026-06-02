#!/usr/bin/env bash
set -euo pipefail
rm -rf /srv/ec-q049
mkdir -p /srv/ec-q049
printf x > /srv/ec-q049/report.txt
chmod 0644 /srv/ec-q049/report.txt
