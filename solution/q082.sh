#!/usr/bin/env bash
set -euo pipefail
{ ps -eo pid,ppid,ni,comm --sort=-%cpu | head -n 10; vmstat 1 2; uptime; } > /root/lfcs-op-mon10.txt
