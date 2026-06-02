#!/usr/bin/env bash
set -euo pipefail
diff -u /var/tmp/ec-q019/original.txt /var/tmp/ec-q019/updated.txt > /root/q019-change.diff || true
