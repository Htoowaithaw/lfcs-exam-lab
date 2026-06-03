#!/usr/bin/env bash
set -euo pipefail
(crontab -l 2>/dev/null || true; echo '*/5 * * * * echo LFCS_Q004 >> /var/log/lfcs-q004.log') | crontab -
