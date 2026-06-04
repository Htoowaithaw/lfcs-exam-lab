#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ "$(sysctl -n net.ipv4.ip_forward)" = '1' ] || fail 'ip_forward is not enabled'
iptables -t nat -S LFCSNAT >/dev/null 2>&1 || fail 'LFCSNAT chain missing'
exact=$(iptables -t nat -S LFCSNAT | awk '{d=""; p=""; dest=""; proto=""; jump=""; for(i=1;i<=NF;i++){if($i=="-d")d=$(i+1); if($i=="--dport")p=$(i+1); if($i=="--to-destination")dest=$(i+1); if($i=="-p")proto=$(i+1); if($i=="-j")jump=$(i+1)} if($1=="-A" && $2=="LFCSNAT" && proto=="tcp" && (d=="192.168.56.11" || d=="192.168.56.11/32") && p=="18602" && jump=="DNAT" && dest=="192.168.56.12:18602") c++} END{print c+0}')
[ "$exact" -ge 1 ] || fail 'exact DNAT rule missing'
wrong=$(iptables -t nat -S LFCSNAT | awk '{p=""; dest=""; for(i=1;i<=NF;i++){if($i=="--dport")p=$(i+1); if($i=="--to-destination")dest=$(i+1)} if($1=="-A" && $2=="LFCSNAT" && p=="18602" && dest!="" && dest!="192.168.56.12:18602") c++} END{print c+0}')
[ "$wrong" -eq 0 ] || fail 'conflicting DNAT rule for requested port exists'
curl -fsS --max-time 5 http://192.168.56.12:18602/lfcs-nat-2.txt | grep -Fxq 'NAT-2-NODE2' || fail 'node2 backend response is wrong'
curl -fsS --max-time 5 http://192.168.56.11:18602/lfcs-nat-2.txt | grep -Fxq 'NAT-2-NODE2' || fail 'node1 port does not reach node2 backend'
echo "RESULT: PASS"
