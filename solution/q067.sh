#!/usr/bin/env bash
set -euo pipefail
cat > /etc/rsyslog.d/lfcs-op-log1.conf <<'EOF'
if $programname == 'lfcs-op-log1-tag' then /var/log/lfcs-op-log1.log
& stop
EOF
systemctl reload-or-restart rsyslog
logger -t lfcs-op-log1-tag 'LFCS-1'
sleep 1
