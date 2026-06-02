#!/usr/bin/env bash
set -euo pipefail
rm -rf /etc/lfcs-q015
mkdir -p /etc/lfcs-q015
cat >/etc/lfcs-q015/hosts.extra <<'EOF'
10.20.30.10 api.lfcs.local
10.20.30.11 old-api.lfcs.local
10.20.30.12 old-api.lfcs.local
EOF
