#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
test -s /root/.ssh/lfcs-q228 || fail 'node1 private key missing'
grep -q '^Host lfcs-node2-4$' /root/.ssh/config || fail 'ssh alias missing'
grep -Eq '^[[:space:]]+HostName[[:space:]]+192.168.56.12$' /root/.ssh/config || fail 'ssh HostName is wrong'
grep -Eq '^[[:space:]]+User[[:space:]]+remoteuser4$' /root/.ssh/config || fail 'ssh User is wrong'
grep -Eq '^[[:space:]]+IdentityFile[[:space:]]+/root/.ssh/lfcs-q228$' /root/.ssh/config || fail 'ssh IdentityFile is wrong'
grep -Eq '^[[:space:]]+IdentitiesOnly[[:space:]]+yes$' /root/.ssh/config || fail 'IdentitiesOnly is not enforced'
grep -Eq '^[[:space:]]+StrictHostKeyChecking[[:space:]]+yes$' /root/.ssh/config || fail 'StrictHostKeyChecking is not enforced'
ssh-keygen -F 192.168.56.12 >/dev/null || fail 'known_hosts entry missing'
ssh -F /root/.ssh/config -o BatchMode=yes lfcs-node2-4 'test "$(id -un)" = "remoteuser4"' || fail 'non-interactive SSH to node2 failed'
echo "RESULT: PASS"
