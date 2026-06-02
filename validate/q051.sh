#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
bad_dir="$(find /srv/ec-q051/project -type d ! -perm 2770 -print -quit)"
[ -z "$bad_dir" ] || fail "directory mode incorrect"
bad_file="$(find /srv/ec-q051/project -type f ! -perm 0660 -print -quit)"
[ -z "$bad_file" ] || fail "file mode incorrect"
bad_group="$(find /srv/ec-q051/project ! -group adm -print -quit)"
[ -z "$bad_group" ] || fail "group ownership incorrect"
echo "RESULT: PASS"
