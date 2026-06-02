#!/usr/bin/env bash
set -euo pipefail
qemu-img create -f qcow2 /var/lib/libvirt/images/lfcs-op-cloud2.qcow2 2G
cat > /var/lib/libvirt/images/lfcs-op-cloud2-meta.yaml <<'EOF'
instance-id: lfcs-op-cloud2
local-hostname: lfcs-op-cloud2
EOF
