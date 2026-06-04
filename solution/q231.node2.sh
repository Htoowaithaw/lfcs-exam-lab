#!/usr/bin/env bash
set -euo pipefail
systemctl enable --now slapd
ldapadd -x -D cn=admin,dc=lfcs,dc=lab -w admin <<'EOF' >/dev/null 2>&1 || true
dn: ou=People,dc=lfcs,dc=lab
objectClass: organizationalUnit
ou: People
EOF
ldapadd -x -D cn=admin,dc=lfcs,dc=lab -w admin <<'EOF'
dn: uid=ldapuser2,ou=People,dc=lfcs,dc=lab
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: ldapuser2
sn: ldapuser2
uid: ldapuser2
uidNumber: 3102
gidNumber: 3102
homeDirectory: /home/ldapuser2
loginShell: /bin/bash
userPassword: password
EOF
