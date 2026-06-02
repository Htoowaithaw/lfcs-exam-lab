#!/usr/bin/env bash
set -euo pipefail
grep -E '^LFCS-[0-9]{4}$' /var/tmp/ec-q039/tickets.txt > /root/q039-tickets.txt
