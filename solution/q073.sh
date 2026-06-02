#!/usr/bin/env bash
set -euo pipefail
cat > /etc/cron.d/lfcs-op-cron15 <<'EOF'
*/15 * * * * root /bin/sh -c 'echo lfcs-op-cron15-ok > /var/tmp/lfcs-op-cron15.stamp'
EOF
chmod 0644 /etc/cron.d/lfcs-op-cron15
