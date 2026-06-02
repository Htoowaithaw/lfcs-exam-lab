#!/usr/bin/env bash
set -euo pipefail
rm -rf /srv/ec-q050
mkdir -p /srv/ec-q050
printf x > /srv/ec-q050/run.sh
chmod 0644 /srv/ec-q050/run.sh
