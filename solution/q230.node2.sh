#!/usr/bin/env bash
set -euo pipefail
systemctl enable --now slapd
ldapadd -x -D cn=admin,dc=lfcs,dc=lab -w admin <<'EOF' >/dev/null 2>&1 || true
dn: ou=People,dc=lfcs,dc=lab
objectClass: organizationalUnit
ou: People
EOF
ldapadd -x -D cn=admin,dc=lfcs,dc=lab -w admin <<'EOF'
dn: uid=ldapuser1,ou=People,dc=lfcs,dc=lab
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: ldapuser1
sn: ldapuser1
uid: ldapuser1
uidNumber: 3101
gidNumber: 3101
homeDirectory: /home/ldapuser1
loginShell: /bin/bash
userPassword: password
EOF
