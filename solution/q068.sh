#!/usr/bin/env bash
set -euo pipefail
cat > /etc/rsyslog.d/lfcs-op-log2.conf <<'EOF'
if $programname == 'lfcs-op-log2-tag' then /var/log/lfcs-op-log2.log
& stop
EOF
systemctl reload-or-restart rsyslog
logger -t lfcs-op-log2-tag 'LFCS-2'
sleep 1
