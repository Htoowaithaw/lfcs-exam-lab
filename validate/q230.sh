#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
getent passwd ldapuser1 | awk -F: '$1=="ldapuser1" && $3==3101 && $6=="/home/ldapuser1" && $7=="/bin/bash" {found=1} END {exit !found}' || fail 'LDAP passwd entry not visible on node1'
ldapsearch -x -H ldap://192.168.56.12/ -b dc=lfcs,dc=lab uid=ldapuser1 uidNumber | grep -q 'uidNumber: 3101' || fail 'LDAP server entry is missing or wrong'
grep -Eq '^uri[[:space:]]+ldap://192.168.56.12/' /etc/nslcd.conf || fail 'node1 LDAP URI is wrong'
grep -Eq '^passwd:.*ldap' /etc/nsswitch.conf || fail 'node1 passwd NSS does not include ldap'
echo "RESULT: PASS"
