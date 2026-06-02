#!/usr/bin/env bash
set -euo pipefail
if ! virsh dominfo lfcs-op-vm3 >/dev/null 2>&1; then echo "RESULT: FAIL - check 1 failed: virsh dominfo lfcs-op-vm3 >/dev/null 2>&1"; exit 1; fi
if ! virsh dumpxml lfcs-op-vm3 | grep -q '<name>lfcs-op-vm3</name>'; then echo "RESULT: FAIL - check 2 failed: virsh dumpxml lfcs-op-vm3 | grep -q '<name>lfcs-op-vm3</name>'"; exit 1; fi
if ! virsh pool-info lfcs-op-vm3-pool | grep -q 'State:[[:space:]]*running'; then echo "RESULT: FAIL - check 3 failed: virsh pool-info lfcs-op-vm3-pool | grep -q 'State:[[:space:]]*running'"; exit 1; fi
if ! virsh pool-info lfcs-op-vm3-pool | grep -q 'Autostart:[[:space:]]*yes'; then echo "RESULT: FAIL - check 4 failed: virsh pool-info lfcs-op-vm3-pool | grep -q 'Autostart:[[:space:]]*yes'"; exit 1; fi
echo "RESULT: PASS"
