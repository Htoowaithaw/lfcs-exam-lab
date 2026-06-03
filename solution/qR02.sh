#!/usr/bin/env bash
set -euo pipefail
setsebool -P httpd_can_network_connect on
