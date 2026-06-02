#!/usr/bin/env bash
set -euo pipefail
setenforce 1
setsebool -P httpd_can_sendmail on
