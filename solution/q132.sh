#!/usr/bin/env bash
set -euo pipefail
useradd -m -s /bin/bash sshuser1
install -d -m 700 -o sshuser1 -g sshuser1 /home/sshuser1/.ssh
ssh-keygen -q -t ed25519 -N '' -f /home/sshuser1/.ssh/id_ed25519
cat /home/sshuser1/.ssh/id_ed25519.pub > /home/sshuser1/.ssh/authorized_keys
chown -R sshuser1:sshuser1 /home/sshuser1/.ssh
chmod 600 /home/sshuser1/.ssh/authorized_keys
for f in /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf; do [ "$f" = "/etc/ssh/sshd_config.d/q132.conf" ] && continue; [ -e "$f" ] && sed -i -E '/^[[:space:]]*PasswordAuthentication[[:space:]]+/s/^/# /' "$f"; done
cat > /etc/ssh/sshd_config.d/q132.conf <<'EOF'
PasswordAuthentication no
PubkeyAuthentication yes
EOF
sshd -t
systemctl restart ssh || systemctl restart sshd
for i in {1..20}; do (systemctl is-active --quiet ssh || systemctl is-active --quiet sshd) && break; sleep 1; done
