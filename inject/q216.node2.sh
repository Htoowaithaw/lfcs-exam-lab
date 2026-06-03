#!/usr/bin/env bash
set -euo pipefail
pkill -f 'lfcs-proxy-2' >/dev/null 2>&1 || true
