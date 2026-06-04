#!/usr/bin/env bash
set -euo pipefail
systemctl enable --now slapd
ldapadd -x -D cn=admin,dc=lfcs,dc=lab -w admin <<'EOF' >/dev/null 2>&1 || true
dn: ou=People,dc=lfcs,dc=lab
objectClass: organizationalUnit
ou: People
EOF
ldapadd -x -D cn=admin,dc=lfcs,dc=lab -w admin <<'EOF'
dn: uid=ldapuser4,ou=People,dc=lfcs,dc=lab
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: ldapuser4
sn: ldapuser4
uid: ldapuser4
uidNumber: 3104
gidNumber: 3104
homeDirectory: /home/ldapuser4
loginShell: /bin/bash
userPassword: password
EOF
