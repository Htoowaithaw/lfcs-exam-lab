#!/usr/bin/env bash
set -euo pipefail
setsebool -P virt_use_nfs off >/dev/null 2>&1 || true
setenforce 1 || true
