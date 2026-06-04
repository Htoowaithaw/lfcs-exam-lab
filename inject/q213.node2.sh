#!/usr/bin/env bash
set -euo pipefail
pkill -f 'lfcs-nat-5' >/dev/null 2>&1 || true
