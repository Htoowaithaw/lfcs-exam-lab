#!/usr/bin/env bash
set -euo pipefail
sort -u /var/tmp/ec-q040/packages.txt > /root/q040-inventory.txt
