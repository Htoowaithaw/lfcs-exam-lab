#!/usr/bin/env bash
set -euo pipefail
if ! test -f /var/lib/libvirt/images/lfcs-op-cloud3.qcow2; then echo "RESULT: FAIL - check 1 failed: test -f /var/lib/libvirt/images/lfcs-op-cloud3.qcow2"; exit 1; fi
if ! qemu-img info /var/lib/libvirt/images/lfcs-op-cloud3.qcow2 | grep -q 'file format: qcow2'; then echo "RESULT: FAIL - check 2 failed: qemu-img info /var/lib/libvirt/images/lfcs-op-cloud3.qcow2 | grep -q 'file format: qcow2'"; exit 1; fi
if ! qemu-img info /var/lib/libvirt/images/lfcs-op-cloud3.qcow2 | grep -q 'virtual size: 3 GiB'; then echo "RESULT: FAIL - check 3 failed: qemu-img info /var/lib/libvirt/images/lfcs-op-cloud3.qcow2 | grep -q 'virtual size: 3 GiB'"; exit 1; fi
if ! grep -q '^instance-id: lfcs-op-cloud3$' /var/lib/libvirt/images/lfcs-op-cloud3-meta.yaml; then echo "RESULT: FAIL - check 4 failed: grep -q '^instance-id: lfcs-op-cloud3\$' /var/lib/libvirt/images/lfcs-op-cloud3-meta.yaml"; exit 1; fi
echo "RESULT: PASS"
