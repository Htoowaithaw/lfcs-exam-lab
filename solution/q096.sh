#!/usr/bin/env bash
set -euo pipefail
virsh define /root/lfcs-op-vm3.xml
virsh pool-define-as --name lfcs-op-vm3-pool --type dir --target /var/lib/libvirt/lfcs-op-vm3-pool
virsh pool-start lfcs-op-vm3-pool
virsh pool-autostart lfcs-op-vm3-pool
