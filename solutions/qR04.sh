#!/usr/bin/env bash
set -euo pipefail
cat >/etc/yum.repos.d/lfcs-r04.repo <<'EOF'
[lfcs-r04]
name=LFCS R04 Local Repo
baseurl=file:///opt/lfcs-r04-repo
enabled=1
gpgcheck=0
EOF
dnf clean all >/dev/null
dnf -y install lfcs-r04-tool
