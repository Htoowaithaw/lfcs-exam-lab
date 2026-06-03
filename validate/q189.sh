#!/usr/bin/env bash
set -euo pipefail
if ! getent passwd limituser2 >/dev/null; then echo "RESULT: FAIL - limit user missing"; exit 1; fi
if ! su - limituser2 -c 'ulimit -n' | grep -q '^2050$'; then echo "RESULT: FAIL - nofile limit not applied"; exit 1; fi
echo "RESULT: PASS"
