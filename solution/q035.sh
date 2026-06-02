#!/usr/bin/env bash
set -euo pipefail
grep '^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*' /var/tmp/ec-q035/hosts.txt > /root/q035-ips.txt
