#!/usr/bin/env bash
set -euo pipefail
if test -f /run/lfcs-ss5.pid; then kill $(cat /run/lfcs-ss5.pid) >/dev/null 2>&1 || true; fi
rm -f /run/lfcs-ss5.pid
