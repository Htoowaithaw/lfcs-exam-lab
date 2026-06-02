#!/usr/bin/env bash
set -euo pipefail
cat > /etc/cron.d/lfcs-op-cron5 <<'EOF'
*/5 * * * * root /bin/sh -c 'echo lfcs-op-cron5-ok > /var/tmp/lfcs-op-cron5.stamp'
EOF
chmod 0644 /etc/cron.d/lfcs-op-cron5
