#!/usr/bin/env bash
set -euo pipefail
cat > /etc/cron.d/lfcs-op-cron10 <<'EOF'
*/10 * * * * root /bin/sh -c 'echo lfcs-op-cron10-ok > /var/tmp/lfcs-op-cron10.stamp'
EOF
chmod 0644 /etc/cron.d/lfcs-op-cron10
