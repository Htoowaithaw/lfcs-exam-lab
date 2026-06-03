#!/usr/bin/env bash
set -euo pipefail
if ! getent passwd limituser1 >/dev/null; then echo "RESULT: FAIL - limit user missing"; exit 1; fi
if ! su - limituser1 -c 'ulimit -n' | grep -q '^2049$'; then echo "RESULT: FAIL - nofile limit not applied"; exit 1; fi
echo "RESULT: PASS"
