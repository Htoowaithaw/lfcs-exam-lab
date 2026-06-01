#!/usr/bin/env bash
set -euo pipefail
ip route del 203.0.113.0/24 >/dev/null 2>&1 || true
