#!/usr/bin/env bash
set -euo pipefail
cat > /root/lfcs-op-docker2/Dockerfile <<'EOF'
FROM lfcs-local-base:1.0
LABEL lfcs.question=q091
CMD ["/bin/busybox", "sleep", "3600"]
EOF
docker build -t lfcs/lfcs-op-docker2:1.0 /root/lfcs-op-docker2
docker run -d --name lfcs-op-docker2-ctr --label lfcs.question=q091 lfcs/lfcs-op-docker2:1.0
