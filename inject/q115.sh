#!/usr/bin/env bash
set -euo pipefail
if test -f /run/lfcs-ss4.pid; then kill $(cat /run/lfcs-ss4.pid) >/dev/null 2>&1 || true; fi
rm -f /run/lfcs-ss4.pid
