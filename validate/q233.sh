#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
getent passwd ldapuser4 | awk -F: '$1=="ldapuser4" && $3==3104 && $6=="/home/ldapuser4" && $7=="/bin/bash" {found=1} END {exit !found}' || fail 'LDAP passwd entry not visible on node1'
ldapsearch -x -H ldap://192.168.56.12/ -b dc=lfcs,dc=lab uid=ldapuser4 uidNumber | grep -q 'uidNumber: 3104' || fail 'LDAP server entry is missing or wrong'
grep -Eq '^uri[[:space:]]+ldap://192.168.56.12/' /etc/nslcd.conf || fail 'node1 LDAP URI is wrong'
grep -Eq '^passwd:.*ldap' /etc/nsswitch.conf || fail 'node1 passwd NSS does not include ldap'
echo "RESULT: PASS"
