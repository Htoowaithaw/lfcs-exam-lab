#!/usr/bin/env bash
set -euo pipefail
systemctl enable --now libvirtd >/dev/null 2>&1 || true
virsh undefine lfcs-op-vm2 >/dev/null 2>&1 || true
virsh pool-destroy lfcs-op-vm2-pool >/dev/null 2>&1 || true
virsh pool-undefine lfcs-op-vm2-pool >/dev/null 2>&1 || true
mkdir -p /var/lib/libvirt/lfcs-op-vm2-pool
cat > /root/lfcs-op-vm2.xml <<'EOF'
<domain type='qemu'>
  <name>lfcs-op-vm2</name>
  <memory unit='MiB'>258</memory>
  <vcpu>1</vcpu>
  <os><type arch='x86_64'>hvm</type></os>
</domain>
EOF
