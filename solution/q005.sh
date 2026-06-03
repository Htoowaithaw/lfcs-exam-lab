#!/usr/bin/env bash
set -euo pipefail
grep -q 'repo.lfcs.local' /etc/hosts || echo '10.10.10.50 repo.lfcs.local' >> /etc/hosts
