#!/usr/bin/env bash
set -euo pipefail
qemu-img create -f qcow2 /var/lib/libvirt/images/lfcs-op-cloud3.qcow2 3G
cat > /var/lib/libvirt/images/lfcs-op-cloud3-meta.yaml <<'EOF'
instance-id: lfcs-op-cloud3
local-hostname: lfcs-op-cloud3
EOF
