#!/usr/bin/env bash
set -euo pipefail
rm -f /etc/lfcs-q014/app.ini
mkdir -p /etc/lfcs-q014
cat >/etc/lfcs-q014/app.ini <<'EOF'
[app]
environment=staging
debug=true
workers=1
listen=127.0.0.1:9000
EOF
