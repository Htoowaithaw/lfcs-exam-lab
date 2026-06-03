#!/usr/bin/env bash
set -euo pipefail
if ! test -f /proc/net/bonding/bondlfcs4; then echo "RESULT: FAIL - bond details missing"; exit 1; fi
if ! grep -q 'Bonding Mode: fault-tolerance' /proc/net/bonding/bondlfcs4; then echo "RESULT: FAIL - bond is not active-backup"; exit 1; fi
if ! grep -q 'Slave Interface: bnd4a' /proc/net/bonding/bondlfcs4; then echo "RESULT: FAIL - first bond slave missing"; exit 1; fi
if ! grep -q 'Slave Interface: bnd4b' /proc/net/bonding/bondlfcs4; then echo "RESULT: FAIL - second bond slave missing"; exit 1; fi
echo "RESULT: PASS"
