#!/usr/bin/env bash
set -euo pipefail
nohup python3 -c "import http.server,socketserver; socketserver.TCPServer.allow_reuse_address=True; h=http.server.SimpleHTTPRequestHandler; open('/tmp/lfcs-nat-3.txt','w').write('NAT-3-NODE2'); import os; os.chdir('/tmp'); socketserver.TCPServer(('192.168.56.12',18603),h).serve_forever()" >/tmp/lfcs-nat-3.log 2>&1 &
