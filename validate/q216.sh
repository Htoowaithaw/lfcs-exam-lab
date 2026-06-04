#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
ss -ltn | awk '{print $4}' | grep -Eq '(^|:)18802$' || fail 'nginx is not listening on requested port'
curl -fsS --max-time 5 http://192.168.56.12:18702/lfcs-proxy-2.txt | grep -Fxq 'PROXY-2-NODE2' || fail 'node2 backend response is wrong'
curl -fsS --max-time 5 http://127.0.0.1:18802/lfcs-proxy-2.txt | grep -Fxq 'PROXY-2-NODE2' || fail 'proxy does not return node2 backend response'
nginx_conf="$(nginx -T 2>/dev/null)"
grep -q 'proxy_pass http://192.168.56.12:18702' <<<"$nginx_conf" || fail 'nginx proxy_pass target is wrong'
echo "RESULT: PASS"
