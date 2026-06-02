#!/usr/bin/env bash
set -euo pipefail
if ! docker image inspect lfcs/lfcs-op-docker2:1.0 >/dev/null 2>&1; then echo "RESULT: FAIL - check 1 failed: docker image inspect lfcs/lfcs-op-docker2:1.0 >/dev/null 2>&1"; exit 1; fi
if ! docker ps --format '{{.Names}}' | grep -Fxq lfcs-op-docker2-ctr; then echo "RESULT: FAIL - check 2 failed: docker ps --format '{{.Names}}' | grep -Fxq lfcs-op-docker2-ctr"; exit 1; fi
if ! test "$(docker inspect -f '{{ index .Config.Labels "lfcs.question" }}' lfcs-op-docker2-ctr)" = "q091"; then echo "RESULT: FAIL - check 3 failed: test '\$(docker inspect -f '{{ index .Config.Labels 'lfcs.question' }}' lfcs-op-docker2-ctr)' = 'q091'"; exit 1; fi
echo "RESULT: PASS"
