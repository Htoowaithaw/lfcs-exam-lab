#!/usr/bin/env bash
set -euo pipefail
rm -f /usr/local/bin/q052-idcopy
cp /usr/bin/id /usr/local/bin/q052-idcopy
chmod 0755 /usr/local/bin/q052-idcopy
