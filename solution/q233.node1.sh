#!/usr/bin/env bash
set -euo pipefail
cat > /etc/nslcd.conf <<'EOF'
uid nslcd
gid nslcd
uri ldap://192.168.56.12/
base dc=lfcs,dc=lab
EOF
sed -i 's/^passwd:.*/passwd:         files systemd ldap/' /etc/nsswitch.conf
sed -i 's/^group:.*/group:          files systemd ldap/' /etc/nsswitch.conf
systemctl enable --now nslcd
systemctl restart nslcd
