#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
from pathlib import Path
p=Path('/etc/systemd/system/lfcs-op-svc1.service')
s=p.read_text()
s=s.replace('/usr/local/bin/lfcs-op-svc1-wrong.sh','/usr/local/bin/lfcs-op-svc1.sh')
p.write_text(s)
PY
systemctl daemon-reload
systemctl enable --now lfcs-op-svc1.service
