#!/usr/bin/env bash
set -euo pipefail
nohup python3 -c "import http.server,socketserver; socketserver.TCPServer.allow_reuse_address=True; h=http.server.SimpleHTTPRequestHandler; open('/tmp/lfcs-nat-6.txt','w').write('NAT-6-NODE2'); import os; os.chdir('/tmp'); socketserver.TCPServer(('192.168.56.12',18606),h).serve_forever()" >/tmp/lfcs-nat-6.log 2>&1 &
