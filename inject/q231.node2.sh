#!/usr/bin/env bash
set -euo pipefail
ldapdelete -x -D cn=admin,dc=lfcs,dc=lab -w admin uid=ldapuser2,ou=People,dc=lfcs,dc=lab >/dev/null 2>&1 || true
ldapdelete -x -D cn=admin,dc=lfcs,dc=lab -w admin ou=People,dc=lfcs,dc=lab >/dev/null 2>&1 || true
