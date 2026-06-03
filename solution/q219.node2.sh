#!/usr/bin/env bash
set -euo pipefail
nohup python3 -c "import http.server,socketserver; socketserver.TCPServer.allow_reuse_address=True; open('/tmp/lfcs-proxy-5.txt','w').write('PROXY-5-NODE2'); import os; os.chdir('/tmp'); socketserver.TCPServer(('192.168.56.12',18705),http.server.SimpleHTTPRequestHandler).serve_forever()" >/tmp/lfcs-proxy-5.log 2>&1 &
