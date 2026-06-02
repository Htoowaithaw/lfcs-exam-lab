#!/usr/bin/env bash
set -euo pipefail
cat > /etc/rsyslog.d/lfcs-op-log4.conf <<'EOF'
if $programname == 'lfcs-op-log4-tag' then /var/log/lfcs-op-log4.log
& stop
EOF
systemctl reload-or-restart rsyslog
logger -t lfcs-op-log4-tag 'LFCS-4'
sleep 1
