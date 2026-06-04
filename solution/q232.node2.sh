#!/usr/bin/env bash
set -euo pipefail
systemctl enable --now slapd
ldapadd -x -D cn=admin,dc=lfcs,dc=lab -w admin <<'EOF' >/dev/null 2>&1 || true
dn: ou=People,dc=lfcs,dc=lab
objectClass: organizationalUnit
ou: People
EOF
ldapadd -x -D cn=admin,dc=lfcs,dc=lab -w admin <<'EOF'
dn: uid=ldapuser3,ou=People,dc=lfcs,dc=lab
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: ldapuser3
sn: ldapuser3
uid: ldapuser3
uidNumber: 3103
gidNumber: 3103
homeDirectory: /home/ldapuser3
loginShell: /bin/bash
userPassword: password
EOF
