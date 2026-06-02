#!/usr/bin/env bash
set -euo pipefail
{ ps -eo pid,ppid,ni,comm --sort=-%cpu | head -n 12; vmstat 1 2; uptime; } > /root/lfcs-op-mon12.txt
