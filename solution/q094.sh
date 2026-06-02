#!/usr/bin/env bash
set -euo pipefail
virsh define /root/lfcs-op-vm1.xml
virsh pool-define-as --name lfcs-op-vm1-pool --type dir --target /var/lib/libvirt/lfcs-op-vm1-pool
virsh pool-start lfcs-op-vm1-pool
virsh pool-autostart lfcs-op-vm1-pool
