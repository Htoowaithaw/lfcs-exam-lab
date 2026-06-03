#!/usr/bin/env bash
set -euo pipefail
if ! pvs /dev/sdg --noheadings -o pv_name | grep -q '/dev/sdg'; then echo "RESULT: FAIL - PV missing on scratch disk"; exit 1; fi
if ! vgs vglfcs7 --noheadings -o vg_name | grep -q 'vglfcs7'; then echo "RESULT: FAIL - VG missing"; exit 1; fi
if ! lvs /dev/vglfcs7/lvdata7 --noheadings -o lv_name | grep -q 'lvdata7'; then echo "RESULT: FAIL - LV missing"; exit 1; fi
if ! findmnt -rn /mnt/lfcs-lvm7 | grep -q '/dev/mapper/vglfcs7-lvdata7'; then echo "RESULT: FAIL - LV is not mounted at requested path"; exit 1; fi
echo "RESULT: PASS"
