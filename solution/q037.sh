#!/usr/bin/env bash
set -euo pipefail
grep -E ' (2[0-9][0-9]|3[0-9][0-9])$' /var/tmp/ec-q037/http.log > /root/q037-http-ok.txt
