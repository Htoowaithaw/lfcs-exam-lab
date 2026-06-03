#!/usr/bin/env bash
set -euo pipefail
ufw default allow incoming
ufw default allow outgoing
ufw allow 18202/tcp
ufw --force enable
