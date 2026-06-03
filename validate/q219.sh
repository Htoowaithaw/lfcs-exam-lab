#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
ss -ltn sport = :18805 | grep -q ':18805' || fail 'nginx is not listening on requested port'
curl -fsS --max-time 5 http://127.0.0.1:18805/lfcs-proxy-5.txt | grep -Fxq 'PROXY-5-NODE2' || fail 'proxy does not return node2 backend response'
nginx -T 2>/dev/null | grep -q 'proxy_pass http://192.168.56.12:18705' || fail 'nginx proxy_pass target is wrong'
echo "RESULT: PASS"
