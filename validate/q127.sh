#!/usr/bin/env bash
set -euo pipefail
if ! nft list table inet lfcs6 >/dev/null 2>&1; then echo "RESULT: FAIL - nft table missing"; exit 1; fi
if ! nft list table inet lfcs6 | grep -q 'tcp dport 18306 accept'; then echo "RESULT: FAIL - nft accept rule missing"; exit 1; fi
echo "RESULT: PASS"
