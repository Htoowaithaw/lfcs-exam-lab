#!/usr/bin/env bash
set -euo pipefail
nohup python3 -c "import socket,time; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1); s.bind(('127.0.0.1',18105)); s.listen(1); time.sleep(3600)" >/tmp/lfcs-ss5.log 2>&1 &
echo $! > /run/lfcs-ss5.pid
