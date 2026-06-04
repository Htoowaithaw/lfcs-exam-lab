#!/usr/bin/env bash
set -euo pipefail
nohup python3 -c "import http.server,socketserver; socketserver.TCPServer.allow_reuse_address=True; open('/tmp/lfcs-proxy-2.txt','w').write('PROXY-2-NODE2'); import os; os.chdir('/tmp'); socketserver.TCPServer(('192.168.56.12',18702),http.server.SimpleHTTPRequestHandler).serve_forever()" >/tmp/lfcs-proxy-2.log 2>&1 &
