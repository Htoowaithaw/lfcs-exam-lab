#!/usr/bin/env bash
set -euo pipefail
sed -i 's#/usr/local/bin/lfcs-q003-missing.sh#/usr/local/bin/lfcs-q003.sh#' /etc/systemd/system/lfcs-q003.service
systemctl daemon-reload
systemctl enable --now lfcs-q003.service
