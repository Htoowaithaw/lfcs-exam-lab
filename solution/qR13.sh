#!/usr/bin/env bash
set -euo pipefail
firewall-cmd --permanent --zone=public --add-port=18401/tcp
firewall-cmd --reload
