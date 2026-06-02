#!/usr/bin/env bash
set -euo pipefail
grep '[0-9][0-9]$' /var/tmp/ec-q034/services.txt > /root/q034-services.txt
