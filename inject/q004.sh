#!/usr/bin/env bash
set -euo pipefail
crontab -r >/dev/null 2>&1 || true
rm -f /var/log/lfcs-q004.log
systemctl enable --now cron >/dev/null
