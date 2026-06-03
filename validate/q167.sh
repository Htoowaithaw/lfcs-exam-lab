#!/usr/bin/env bash
set -euo pipefail
if ! pvs /dev/sdg --noheadings -o pv_name | grep -q '/dev/sdg'; then echo "RESULT: FAIL - PV missing on scratch disk"; exit 1; fi
if ! vgs vglfcs8 --noheadings -o vg_name | grep -q 'vglfcs8'; then echo "RESULT: FAIL - VG missing"; exit 1; fi
if ! lvs /dev/vglfcs8/lvdata8 --noheadings -o lv_name | grep -q 'lvdata8'; then echo "RESULT: FAIL - LV missing"; exit 1; fi
if ! findmnt -rn /mnt/lfcs-lvm8 | grep -q '/dev/mapper/vglfcs8-lvdata8'; then echo "RESULT: FAIL - LV is not mounted at requested path"; exit 1; fi
echo "RESULT: PASS"
