#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
from pathlib import Path
p=Path('/etc/systemd/system/lfcs-op-svc3.service')
s=p.read_text()
s=s.replace('/usr/local/bin/lfcs-op-svc3-wrong.sh','/usr/local/bin/lfcs-op-svc3.sh')
p.write_text(s)
PY
systemctl daemon-reload
systemctl enable --now lfcs-op-svc3.service
