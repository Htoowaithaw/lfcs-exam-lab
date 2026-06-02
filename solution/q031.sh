#!/usr/bin/env bash
set -euo pipefail
grep -F 'api/v1' /var/tmp/ec-q031/input.log > /root/q031-matches.txt
