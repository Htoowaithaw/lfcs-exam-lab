#!/usr/bin/env bash
set -euo pipefail
pkill -f 'lfcs-nat-4' >/dev/null 2>&1 || true
