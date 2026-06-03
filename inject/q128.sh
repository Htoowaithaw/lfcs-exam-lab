#!/usr/bin/env bash
set -euo pipefail
ip route delete 198.51.1.0/24 >/dev/null 2>&1 || true
