#!/usr/bin/env bash
set -euo pipefail
pkill -f 'lfcs-proxy-3' >/dev/null 2>&1 || true
