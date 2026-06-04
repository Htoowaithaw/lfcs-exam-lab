#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
grep -Eq '^server[[:space:]]+192.168.56.12[[:space:]]+iburst([[:space:]]*$|[[:space:]]+#)' /etc/chrony/chrony.conf || fail 'node1 chrony source is wrong'
sources=$(awk '$1 !~ /^#/ && ($1=="server" || $1=="pool") {print $1" "$2}' /etc/chrony/chrony.conf)
[ "$(printf '%s\n' "$sources" | sed '/^$/d' | wc -l)" -eq 1 ] || fail 'node1 has extra chrony sources'
printf '%s\n' "$sources" | grep -qx 'server 192.168.56.12' || fail 'node1 chrony source is not only node2'
systemctl is-active --quiet chrony || fail 'chrony is not active on node1'
chronyc sources -n | grep -q '192.168.56.12' || fail 'node2 is not listed as chrony source'
timeout 3 bash -c '</dev/udp/192.168.56.12/123' || true
echo "RESULT: PASS"
