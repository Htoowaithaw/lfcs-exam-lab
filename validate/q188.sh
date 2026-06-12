#!/usr/bin/env bash
set -euo pipefail
if ! getent passwd limituser1 >/dev/null; then echo "RESULT: FAIL - limit user missing"; exit 1; fi
if ! su - limituser1 -c 'ulimit -n' | grep -q '^2049$'; then echo "RESULT: FAIL - nofile limit not applied"; exit 1; fi
[ "$(su - limituser1 -c 'ulimit -Sn')" = '2049' ] || { echo "RESULT: FAIL - soft nofile limit is wrong"; exit 1; }
[ "$(su - limituser1 -c 'ulimit -Hn')" = '2049' ] || { echo "RESULT: FAIL - hard nofile limit is wrong"; exit 1; }
echo "RESULT: PASS"
