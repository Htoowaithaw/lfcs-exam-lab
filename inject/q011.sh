#!/usr/bin/env bash
set -euo pipefail
rm -rf /srv/lfcs/ec-layout /var/tmp/ec-q011
mkdir -p /var/tmp/ec-q011
printf 'PORT=8080\nMODE=dev\n' > /var/tmp/ec-q011/app.conf
