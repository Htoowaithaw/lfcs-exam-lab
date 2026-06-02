#!/usr/bin/env bash
set -euo pipefail
cat > /root/lfcs-op-docker4/Dockerfile <<'EOF'
FROM lfcs-local-base:1.0
LABEL lfcs.question=q093
CMD ["/bin/busybox", "sleep", "3600"]
EOF
docker build -t lfcs/lfcs-op-docker4:1.0 /root/lfcs-op-docker4
docker run -d --name lfcs-op-docker4-ctr --label lfcs.question=q093 lfcs/lfcs-op-docker4:1.0
