#!/usr/bin/env bash
set -euo pipefail
install -d -m 700 /root/.ssh
ssh-keygen -q -t ed25519 -N '' -f /root/.ssh/lfcs-q229
cp /root/.ssh/lfcs-q229.pub /vagrant/.tmp-q229.pub
ssh-keyscan -H 192.168.56.12 >> /root/.ssh/known_hosts 2>/dev/null
cat > /root/.ssh/config <<'EOF'
Host lfcs-node2-5
  HostName 192.168.56.12
  User remoteuser5
  IdentityFile /root/.ssh/lfcs-q229
  IdentitiesOnly yes
  StrictHostKeyChecking yes
EOF
chmod 600 /root/.ssh/config
