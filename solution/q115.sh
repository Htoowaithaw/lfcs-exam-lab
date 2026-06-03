#!/usr/bin/env bash
set -euo pipefail
nohup python3 -c "import socket,time; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1); s.bind(('127.0.0.1',18104)); s.listen(1); time.sleep(3600)" >/tmp/lfcs-ss4.log 2>&1 &
echo $! > /run/lfcs-ss4.pid
