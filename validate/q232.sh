#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
getent passwd ldapuser3 | awk -F: '$1=="ldapuser3" && $3==3103 && $6=="/home/ldapuser3" && $7=="/bin/bash" {found=1} END {exit !found}' || fail 'LDAP passwd entry not visible on node1'
ldapsearch -x -H ldap://192.168.56.12/ -b dc=lfcs,dc=lab uid=ldapuser3 uidNumber | grep -q 'uidNumber: 3103' || fail 'LDAP server entry is missing or wrong'
grep -Eq '^uri[[:space:]]+ldap://192.168.56.12/' /etc/nslcd.conf || fail 'node1 LDAP URI is wrong'
grep -Eq '^passwd:.*ldap' /etc/nsswitch.conf || fail 'node1 passwd NSS does not include ldap'
echo "RESULT: PASS"
