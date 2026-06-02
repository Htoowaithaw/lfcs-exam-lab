#!/usr/bin/env bash
set -euo pipefail
pid=$(cat /run/lfcs-op-proc8.pid)
renice -n 8 -p "$pid" >/dev/null
echo "$pid" > /root/lfcs-op-proc8.answer
