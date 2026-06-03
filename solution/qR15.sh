#!/usr/bin/env bash
set -euo pipefail
firewall-cmd --permanent --zone=public --add-port=18403/tcp
firewall-cmd --reload
