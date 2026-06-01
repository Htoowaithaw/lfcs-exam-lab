#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/lfcs-q001 /root/q001-logs.tar.gz
mkdir -p /var/tmp/lfcs-q001/app /var/tmp/lfcs-q001/db
printf 'app-one\n' > /var/tmp/lfcs-q001/app/app.log
printf 'db-one\n' > /var/tmp/lfcs-q001/db/db.log
printf 'ignore me\n' > /var/tmp/lfcs-q001/app/readme.txt
