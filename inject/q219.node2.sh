#!/usr/bin/env bash
set -euo pipefail
pkill -f 'lfcs-proxy-5' >/dev/null 2>&1 || true
