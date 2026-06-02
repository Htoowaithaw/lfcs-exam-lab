#!/usr/bin/env bash
set -euo pipefail
virsh define /root/lfcs-op-vm2.xml
virsh pool-define-as --name lfcs-op-vm2-pool --type dir --target /var/lib/libvirt/lfcs-op-vm2-pool
virsh pool-start lfcs-op-vm2-pool
virsh pool-autostart lfcs-op-vm2-pool
