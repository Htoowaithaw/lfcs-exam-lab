#!/usr/bin/env bash
set -euo pipefail
firewall-cmd --permanent --zone=public --add-port=8443/tcp >/dev/null
firewall-cmd --reload >/dev/null
