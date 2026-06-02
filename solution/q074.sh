#!/usr/bin/env bash
set -euo pipefail
cat > /etc/apt/sources.list.d/lfcs-op-apt1.list <<'EOF'
deb [trusted=yes] file:/opt/lfcs-apt-repo ./
EOF
apt-get update -o Dir::Etc::sourcelist='sources.list.d/lfcs-op-apt1.list' -o Dir::Etc::sourceparts='-' -o APT::Get::List-Cleanup='0'
apt-get install -y --no-install-recommends lfcs-apt-tool
