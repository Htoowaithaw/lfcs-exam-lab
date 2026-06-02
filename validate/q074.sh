#!/usr/bin/env bash
set -euo pipefail
if ! test -f /etc/apt/sources.list.d/lfcs-op-apt1.list; then echo "RESULT: FAIL - check 1 failed: test -f /etc/apt/sources.list.d/lfcs-op-apt1.list"; exit 1; fi
if ! grep -q 'file:/opt/lfcs-apt-repo' /etc/apt/sources.list.d/lfcs-op-apt1.list; then echo "RESULT: FAIL - check 2 failed: grep -q 'file:/opt/lfcs-apt-repo' /etc/apt/sources.list.d/lfcs-op-apt1.list"; exit 1; fi
if ! dpkg -s lfcs-apt-tool >/dev/null 2>&1; then echo "RESULT: FAIL - check 3 failed: dpkg -s lfcs-apt-tool >/dev/null 2>&1"; exit 1; fi
if ! command -v lfcs-apt-tool >/dev/null 2>&1; then echo "RESULT: FAIL - check 4 failed: command -v lfcs-apt-tool >/dev/null 2>&1"; exit 1; fi
echo "RESULT: PASS"
