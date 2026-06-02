#!/usr/bin/env bash
set -euo pipefail
systemctl enable --now docker >/dev/null 2>&1 || true
docker rm -f lfcs-op-docker3-ctr >/dev/null 2>&1 || true
docker rmi -f lfcs/lfcs-op-docker3:1.0 >/dev/null 2>&1 || true
rm -rf /root/lfcs-op-docker3
mkdir -p /root/lfcs-op-docker3
cat > /root/lfcs-op-docker3/Dockerfile <<'EOF'
FROM lfcs-local-base:1.0
LABEL lfcs.seed=wrong
CMD ["/bin/busybox", "sleep", "3600"]
EOF
