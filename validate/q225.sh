#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
test -s /root/.ssh/lfcs-q225 || fail 'node1 private key missing'
grep -q '^Host lfcs-node2-1$' /root/.ssh/config || fail 'ssh alias missing'
grep -q 'HostName 192.168.56.12' /root/.ssh/config || fail 'ssh HostName is wrong'
ssh-keygen -F 192.168.56.12 >/dev/null || fail 'known_hosts entry missing'
ssh -F /root/.ssh/config -o BatchMode=yes lfcs-node2-1 true || fail 'non-interactive SSH to node2 failed'
echo "RESULT: PASS"
