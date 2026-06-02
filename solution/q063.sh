#!/usr/bin/env bash
set -euo pipefail
pid=$(cat /run/lfcs-op-proc5.pid)
renice -n 5 -p "$pid" >/dev/null
echo "$pid" > /root/lfcs-op-proc5.answer
