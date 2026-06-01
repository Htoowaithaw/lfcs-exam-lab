#!/usr/bin/env bash
set -euo pipefail
restorecon -Rv /var/www/html/lfcs-r01 >/dev/null
