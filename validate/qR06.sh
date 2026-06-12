#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/yum.repos.d/lfcs-r06-local.repo; then echo "RESULT: FAIL - check 1 failed: test -f /etc/yum.repos.d/lfcs-r06-local.repo"; exit 1; fi
if ! grep -q 'baseurl=file:///opt/lfcs-r04-repo' /etc/yum.repos.d/lfcs-r06-local.repo; then echo "RESULT: FAIL - check 2 failed: grep -q 'baseurl=file:///opt/lfcs-r04-repo' /etc/yum.repos.d/lfcs-r06-local.repo"; exit 1; fi
if ! rpm -q lfcs-r04-tool >/dev/null 2>&1; then echo "RESULT: FAIL - check 3 failed: rpm -q lfcs-r04-tool >/dev/null 2>&1"; exit 1; fi
grep -Eq '^[[:space:]]*gpgcheck=0[[:space:]]*$' /etc/yum.repos.d/lfcs-r06-local.repo || { echo "RESULT: FAIL - gpgcheck is not disabled"; exit 1; }
echo "RESULT: PASS"
