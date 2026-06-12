#!/usr/bin/env bash
set -euo pipefail
if ! getent passwd limituser2 >/dev/null; then echo "RESULT: FAIL - limit user missing"; exit 1; fi
if ! su - limituser2 -c 'ulimit -n' | grep -q '^2050$'; then echo "RESULT: FAIL - nofile limit not applied"; exit 1; fi
[ "$(su - limituser2 -c 'ulimit -Sn')" = '2050' ] || { echo "RESULT: FAIL - soft nofile limit is wrong"; exit 1; }
[ "$(su - limituser2 -c 'ulimit -Hn')" = '2050' ] || { echo "RESULT: FAIL - hard nofile limit is wrong"; exit 1; }
echo "RESULT: PASS"
