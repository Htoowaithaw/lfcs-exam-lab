#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }
git -C /var/tmp/ec-q058/repo rev-parse --abbrev-ref HEAD | grep -qx 'feature/ec-q058' && test -f /var/tmp/ec-q058/repo/feature.txt && grep -qx enabled /var/tmp/ec-q058/repo/feature.txt && git -C /var/tmp/ec-q058/repo log -1 --pretty=%s | grep -qx 'add feature flag' || fail "git state incorrect"
echo "RESULT: PASS"
