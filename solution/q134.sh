#!/usr/bin/env bash
set -euo pipefail
useradd -m -s /bin/bash sshuser3
install -d -m 700 -o sshuser3 -g sshuser3 /home/sshuser3/.ssh
ssh-keygen -q -t ed25519 -N '' -f /home/sshuser3/.ssh/id_ed25519
cat /home/sshuser3/.ssh/id_ed25519.pub > /home/sshuser3/.ssh/authorized_keys
chown -R sshuser3:sshuser3 /home/sshuser3/.ssh
chmod 600 /home/sshuser3/.ssh/authorized_keys
for f in /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf; do [ "$f" = "/etc/ssh/sshd_config.d/q134.conf" ] && continue; [ -e "$f" ] && sed -i -E '/^[[:space:]]*PasswordAuthentication[[:space:]]+/s/^/# /' "$f"; done
cat > /etc/ssh/sshd_config.d/q134.conf <<'EOF'
PasswordAuthentication no
PubkeyAuthentication yes
EOF
sshd -t
systemctl restart ssh || systemctl restart sshd
for i in {1..20}; do (systemctl is-active --quiet ssh || systemctl is-active --quiet sshd) && break; sleep 1; done
