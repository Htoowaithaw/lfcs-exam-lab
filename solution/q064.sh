#!/usr/bin/env bash
set -euo pipefail
pid=$(cat /run/lfcs-op-proc6.pid)
renice -n 6 -p "$pid" >/dev/null
echo "$pid" > /root/lfcs-op-proc6.answer
