#!/usr/bin/env bash
set -euo pipefail
if ! nft list table inet lfcs4 >/dev/null 2>&1; then echo "RESULT: FAIL - nft table missing"; exit 1; fi
if ! nft list table inet lfcs4 | grep -q 'tcp dport 18304 accept'; then echo "RESULT: FAIL - nft accept rule missing"; exit 1; fi
nft list chain inet lfcs4 input | grep -Eq 'type filter hook input' || { echo "RESULT: FAIL - input chain is not a base input hook"; exit 1; }
echo "RESULT: PASS"
