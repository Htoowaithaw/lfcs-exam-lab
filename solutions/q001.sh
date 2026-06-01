#!/usr/bin/env bash
set -euo pipefail
cd /var/tmp/lfcs-q001
tar -czf /root/q001-logs.tar.gz app/app.log db/db.log
