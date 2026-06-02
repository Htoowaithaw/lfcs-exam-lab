#!/usr/bin/env bash
set -euo pipefail
grep -E '^(web|db)[0-9]{2}-prod$' /var/tmp/ec-q038/hosts.txt > /root/q038-prod-hosts.txt
