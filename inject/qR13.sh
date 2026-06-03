#!/usr/bin/env bash
set -euo pipefail
systemctl enable --now firewalld >/dev/null 2>&1 || true
firewall-cmd --permanent --remove-port=18401/tcp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null
