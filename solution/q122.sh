#!/usr/bin/env bash
set -euo pipefail
ufw default allow incoming
ufw default allow outgoing
ufw allow 18201/tcp
ufw --force enable
