#!/usr/bin/env bash
set -euo pipefail
rm -f /etc/nginx/sites-enabled/lfcs-proxy1 /etc/nginx/sites-available/lfcs-proxy1
systemctl restart nginx >/dev/null 2>&1 || true
