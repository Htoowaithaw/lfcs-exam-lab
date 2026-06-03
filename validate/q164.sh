#!/usr/bin/env bash
set -euo pipefail
if ! pvs /dev/sdg --noheadings -o pv_name | grep -q '/dev/sdg'; then echo "RESULT: FAIL - PV missing on scratch disk"; exit 1; fi
if ! vgs vglfcs5 --noheadings -o vg_name | grep -q 'vglfcs5'; then echo "RESULT: FAIL - VG missing"; exit 1; fi
if ! lvs /dev/vglfcs5/lvdata5 --noheadings -o lv_name | grep -q 'lvdata5'; then echo "RESULT: FAIL - LV missing"; exit 1; fi
if ! findmnt -rn /mnt/lfcs-lvm5 | grep -q '/dev/mapper/vglfcs5-lvdata5'; then echo "RESULT: FAIL - LV is not mounted at requested path"; exit 1; fi
echo "RESULT: PASS"
