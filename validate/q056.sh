#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
lsattr /srv/ec-q056/locked.conf | awk '{print $1}' | grep -q 'i' || fail "ACL or attribute requirement not met"
echo "RESULT: PASS"
