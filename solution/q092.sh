#!/usr/bin/env bash
set -euo pipefail
cat > /root/lfcs-op-docker3/Dockerfile <<'EOF'
FROM lfcs-local-base:1.0
LABEL lfcs.question=q092
CMD ["/bin/busybox", "sleep", "3600"]
EOF
docker build -t lfcs/lfcs-op-docker3:1.0 /root/lfcs-op-docker3
docker run -d --name lfcs-op-docker3-ctr --label lfcs.question=q092 lfcs/lfcs-op-docker3:1.0
