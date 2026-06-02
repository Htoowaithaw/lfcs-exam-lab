#!/usr/bin/env bash
set -euo pipefail
nohup bash -c 'exec sleep 3600' >/tmp/lfcs-op-proc6.out 2>&1 &
echo $! > /run/lfcs-op-proc6.pid
rm -f /root/lfcs-op-proc6.answer
