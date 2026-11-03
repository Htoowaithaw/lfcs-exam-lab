#!/usr/bin/env bash
set -euo pipefail
systemctl enable --now libvirtd >/dev/null 2>&1 || true
virsh undefine lfcs-op-vm3 >/dev/null 2>&1 || true
virsh pool-destroy lfcs-op-vm3-pool >/dev/null 2>&1 || true
virsh pool-undefine lfcs-op-vm3-pool >/dev/null 2>&1 || true
mkdir -p /var/lib/libvirt/lfcs-op-vm3-pool
# Domain arch/machine must match the host CPU libvirt/QEMU is actually running
# on (amd64 Vagrant boxes -> x86_64 guests, arm64 boxes -> aarch64 guests);
# virsh define can reject a mismatched arch at define-time, before the domain
# is ever started.
case "$(uname -m)" in
  aarch64|arm64) DOM_OS_TYPE="<type arch='aarch64' machine='virt'>hvm</type>" ;;
  *)             DOM_OS_TYPE="<type arch='x86_64'>hvm</type>" ;;
esac
cat > /root/lfcs-op-vm3.xml <<EOF
<domain type='qemu'>
  <name>lfcs-op-vm3</name>
  <memory unit='MiB'>259</memory>
  <vcpu>2</vcpu>
  <os>${DOM_OS_TYPE}</os>
</domain>
EOF
