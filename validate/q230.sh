#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
getent passwd ldapuser1 | awk -F: '$1=="ldapuser1" && $3==3101 && $6=="/home/ldapuser1" && $7=="/bin/bash" {found=1} END {exit !found}' || fail 'LDAP passwd entry not visible on node1'
entry=$(ldapsearch -LLL -x -H ldap://192.168.56.12/ -b uid=ldapuser1,ou=People,dc=lfcs,dc=lab uid uidNumber cn sn homeDirectory loginShell objectClass 2>/dev/null)
printf '%s\n' "$entry" | grep -qx 'dn: uid=ldapuser1,ou=People,dc=lfcs,dc=lab' || fail 'LDAP user DN/base is wrong'
printf '%s\n' "$entry" | grep -qx 'uid: ldapuser1' || fail 'LDAP uid attribute is wrong'
printf '%s\n' "$entry" | grep -qx 'uidNumber: 3101' || fail 'LDAP uidNumber is wrong'
printf '%s\n' "$entry" | grep -qx 'cn: ldapuser1' || fail 'LDAP cn is wrong'
printf '%s\n' "$entry" | grep -qx 'sn: ldapuser1' || fail 'LDAP sn is wrong'
printf '%s\n' "$entry" | grep -qx 'homeDirectory: /home/ldapuser1' || fail 'LDAP homeDirectory is wrong'
printf '%s\n' "$entry" | grep -qx 'loginShell: /bin/bash' || fail 'LDAP loginShell is wrong'
printf '%s\n' "$entry" | grep -qx 'objectClass: posixAccount' || fail 'LDAP objectClass posixAccount missing'
grep -Eq '^uri[[:space:]]+ldap://192.168.56.12/' /etc/nslcd.conf || fail 'node1 LDAP URI is wrong'
grep -Eq '^base[[:space:]]+dc=lfcs,dc=lab' /etc/nslcd.conf || fail 'node1 LDAP base DN is wrong'
grep -Eq '^passwd:.*ldap' /etc/nsswitch.conf || fail 'node1 passwd NSS does not include ldap'
echo "RESULT: PASS"
