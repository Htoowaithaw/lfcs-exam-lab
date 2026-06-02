#!/usr/bin/env bash
set -euo pipefail
cat > /etc/rsyslog.d/lfcs-op-log3.conf <<'EOF'
if $programname == 'lfcs-op-log3-tag' then /var/log/lfcs-op-log3.log
& stop
EOF
systemctl reload-or-restart rsyslog
logger -t lfcs-op-log3-tag 'LFCS-3'
sleep 1
