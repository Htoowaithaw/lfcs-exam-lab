#!/usr/bin/env bash
set -euo pipefail
qemu-img create -f qcow2 /var/lib/libvirt/images/lfcs-op-cloud1.qcow2 1G
cat > /var/lib/libvirt/images/lfcs-op-cloud1-meta.yaml <<'EOF'
instance-id: lfcs-op-cloud1
local-hostname: lfcs-op-cloud1
EOF
