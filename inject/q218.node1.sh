#!/usr/bin/env bash
set -euo pipefail
rm -f /etc/nginx/sites-enabled/lfcs-proxy4 /etc/nginx/sites-available/lfcs-proxy4
systemctl restart nginx >/dev/null 2>&1 || true
