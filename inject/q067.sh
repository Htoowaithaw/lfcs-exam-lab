#!/usr/bin/env bash
set -euo pipefail
rm -f /etc/rsyslog.d/lfcs-op-log1.conf /var/log/lfcs-op-log1.log
systemctl enable --now rsyslog >/dev/null 2>&1 || true
systemctl restart rsyslog >/dev/null 2>&1 || true
