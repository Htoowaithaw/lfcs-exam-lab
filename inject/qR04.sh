#!/usr/bin/env bash
set -euo pipefail
dnf -y remove lfcs-r04-tool >/dev/null 2>&1 || true
rm -f /etc/yum.repos.d/lfcs-r04.repo
[ -d /opt/lfcs-r04-repo/repodata ] || { echo "qR04 local repo missing from base"; exit 1; }
mkdir -p /etc/yum.repos.d/lfcs-disabled
find /etc/yum.repos.d -maxdepth 1 -type f -name '*.repo' ! -name 'lfcs-r04.repo' -exec mv {} /etc/yum.repos.d/lfcs-disabled/ \;
dnf clean all >/dev/null
