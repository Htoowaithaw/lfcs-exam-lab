#!/usr/bin/env bash
set -euo pipefail
ufw --force reset >/dev/null 2>&1 || true
ufw default allow incoming >/dev/null
ufw default allow outgoing >/dev/null
