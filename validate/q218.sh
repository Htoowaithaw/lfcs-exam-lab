#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
ss -ltn | awk '{print $4}' | grep -Eq '(^|:)18804$' || fail 'nginx is not listening on requested port'
curl -fsS --max-time 5 http://192.168.56.12:18704/lfcs-proxy-4.txt | grep -Fxq 'PROXY-4-NODE2' || fail 'node2 backend response is wrong'
curl -fsS --max-time 5 http://127.0.0.1:18804/lfcs-proxy-4.txt | grep -Fxq 'PROXY-4-NODE2' || fail 'proxy does not return node2 backend response'
nginx_conf="$(nginx -T 2>/dev/null)"
grep -q 'proxy_pass http://192.168.56.12:18704' <<<"$nginx_conf" || fail 'nginx proxy_pass target is wrong'
echo "RESULT: PASS"
