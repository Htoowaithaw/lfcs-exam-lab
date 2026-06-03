#!/usr/bin/env bash
set -euo pipefail
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -N LFCSNAT || true
iptables -t nat -C OUTPUT -j LFCSNAT 2>/dev/null || iptables -t nat -A OUTPUT -j LFCSNAT
iptables -t nat -A LFCSNAT -p tcp -d 192.168.56.11 --dport 18604 -j DNAT --to-destination 192.168.56.12:18604
