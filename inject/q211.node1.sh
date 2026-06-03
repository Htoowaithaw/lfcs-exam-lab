#!/usr/bin/env bash
set -euo pipefail
iptables -t nat -F LFCSNAT >/dev/null 2>&1 || true
iptables -t nat -D OUTPUT -j LFCSNAT >/dev/null 2>&1 || true
iptables -t nat -X LFCSNAT >/dev/null 2>&1 || true
sysctl -w net.ipv4.ip_forward=0 >/dev/null 2>&1 || true
