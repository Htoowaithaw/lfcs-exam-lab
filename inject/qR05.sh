#!/usr/bin/env bash
set -euo pipefail
dnf remove -y lfcs-r04-tool >/dev/null 2>&1 || true
mkdir -p /etc/yum.repos.d
rm -f /etc/yum.repos.d/lfcs-r05-local.repo
dnf clean all >/dev/null 2>&1 || true
