#!/usr/bin/env bash
set -euo pipefail
setsebool -P httpd_can_sendmail off >/dev/null 2>&1 || true
setenforce 1 || true
