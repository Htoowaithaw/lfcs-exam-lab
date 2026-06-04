#!/usr/bin/env bash
set -euo pipefail
{
  echo '=== TOP CPU ==='
  ps -eo pid,ppid,%cpu,%mem,comm --sort=-%cpu | head -n 8
  echo '=== VMSTAT ==='
  vmstat 1 2
  echo '=== LOAD ==='
  uptime
} > /root/lfcs-resource-report.txt
chown root:root /root/lfcs-resource-report.txt
chmod 0640 /root/lfcs-resource-report.txt
