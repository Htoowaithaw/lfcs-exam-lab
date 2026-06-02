#!/usr/bin/env bash
set -euo pipefail
if ! test -x /usr/local/bin/lfcs-hello-op3; then echo "RESULT: FAIL - check 1 failed: test -x /usr/local/bin/lfcs-hello-op3"; exit 1; fi
if ! test "$(/usr/local/bin/lfcs-hello-op3)" = "LFCS-COMPILED-3"; then echo "RESULT: FAIL - check 2 failed: test '\$(/usr/local/bin/lfcs-hello-op3)' = 'LFCS-COMPILED-3'"; exit 1; fi
echo "RESULT: PASS"
