#!/usr/bin/env bash
set -euo pipefail
grep -F 'ERROR' /var/tmp/ec-q030/input.log > /root/q030-matches.txt
