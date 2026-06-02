#!/usr/bin/env bash
set -euo pipefail
setsebool -P nis_enabled off >/dev/null 2>&1 || true
setenforce 1 || true
