#!/usr/bin/env bash
set -euo pipefail
nohup python3 -c "import http.server,socketserver; socketserver.TCPServer.allow_reuse_address=True; open('/tmp/lfcs-proxy-3.txt','w').write('PROXY-3-NODE2'); import os; os.chdir('/tmp'); socketserver.TCPServer(('192.168.56.12',18703),http.server.SimpleHTTPRequestHandler).serve_forever()" >/tmp/lfcs-proxy-3.log 2>&1 &
