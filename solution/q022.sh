#!/usr/bin/env bash
set -euo pipefail
gzip -c /var/tmp/ec-q022/audit.log > /root/q022-audit.log.gz
