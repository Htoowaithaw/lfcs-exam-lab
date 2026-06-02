#!/usr/bin/env bash
set -euo pipefail
cat > /root/lfcs-op-docker1/Dockerfile <<'EOF'
FROM lfcs-local-base:1.0
LABEL lfcs.question=q090
CMD ["/bin/busybox", "sleep", "3600"]
EOF
docker build -t lfcs/lfcs-op-docker1:1.0 /root/lfcs-op-docker1
docker run -d --name lfcs-op-docker1-ctr --label lfcs.question=q090 lfcs/lfcs-op-docker1:1.0
