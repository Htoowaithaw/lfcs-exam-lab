#!/usr/bin/env bash
set -euo pipefail
rm -rf /srv/ec-q013 /var/tmp/ec-q013
mkdir -p /var/tmp/ec-q013/incoming
printf '# run\n' > /var/tmp/ec-q013/incoming/deploy.sh
printf '# clean\n' > /var/tmp/ec-q013/incoming/clean.sh
printf 'notes\n' > /var/tmp/ec-q013/incoming/readme.md
printf 'id,value\n1,blue\n' > /var/tmp/ec-q013/incoming/report.csv
chmod 0644 /var/tmp/ec-q013/incoming/*.sh
