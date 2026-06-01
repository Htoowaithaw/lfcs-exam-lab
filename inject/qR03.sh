#!/usr/bin/env bash
set -euo pipefail
systemctl enable --now firewalld
firewall-cmd --zone=public --remove-port=8443/tcp >/dev/null 2>&1 || true
firewall-cmd --permanent --zone=public --remove-port=8443/tcp >/dev/null 2>&1 || true
firewall-cmd --reload >/dev/null
