#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
[ -f /etc/yum.repos.d/lfcs-r04.repo ] || fail "repo file missing"
grep -Eq '^[[:space:]]*baseurl=file:///opt/lfcs-r04-repo' /etc/yum.repos.d/lfcs-r04.repo || fail "baseurl incorrect"
grep -Eq '^[[:space:]]*gpgcheck=0' /etc/yum.repos.d/lfcs-r04.repo || fail "gpgcheck not disabled"
rpm -q lfcs-r04-tool >/dev/null 2>&1 || fail "lfcs-r04-tool not installed"
[ -x /usr/local/bin/lfcs-r04-tool ] || fail "tool executable missing"
echo "RESULT: PASS"
