#!/usr/bin/env bash
set -euo pipefail
mkdir -p /etc/yum.repos.d
cat > /etc/yum.repos.d/lfcs-r05-local.repo <<'EOF'
[lfcs-r05-local]
name=lfcs-r05-local
baseurl=file:///opt/lfcs-r04-repo
enabled=1
gpgcheck=0
metadata_expire=1h
EOF
dnf --disablerepo='*' --enablerepo='lfcs-r05-local' install -y lfcs-r04-tool
