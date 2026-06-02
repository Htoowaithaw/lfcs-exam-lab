#!/usr/bin/env bash
set -euo pipefail
apt-get purge -y lfcs-apt-tool >/dev/null 2>&1 || true
rm -f /etc/apt/sources.list.d/lfcs-op-apt3.list
rm -rf /var/lib/apt/lists/*lfcs-apt-repo*
