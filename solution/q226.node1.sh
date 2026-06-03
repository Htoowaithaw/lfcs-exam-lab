#!/usr/bin/env bash
set -euo pipefail
install -d -m 700 /root/.ssh
ssh-keygen -q -t ed25519 -N '' -f /root/.ssh/lfcs-q226
cp /root/.ssh/lfcs-q226.pub /vagrant/.tmp-q226.pub
ssh-keyscan -H 192.168.56.12 >> /root/.ssh/known_hosts 2>/dev/null
cat > /root/.ssh/config <<'EOF'
Host lfcs-node2-2
  HostName 192.168.56.12
  User remoteuser2
  IdentityFile /root/.ssh/lfcs-q226
  IdentitiesOnly yes
  StrictHostKeyChecking yes
EOF
chmod 600 /root/.ssh/config
