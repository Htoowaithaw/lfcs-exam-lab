#!/usr/bin/env bash
set -euo pipefail
pid=$(cat /run/lfcs-op-proc7.pid)
renice -n 7 -p "$pid" >/dev/null
echo "$pid" > /root/lfcs-op-proc7.answer
