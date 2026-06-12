#!/usr/bin/env bash
set -euo pipefail
if ! getent passwd limituser3 >/dev/null; then echo "RESULT: FAIL - limit user missing"; exit 1; fi
if ! su - limituser3 -c 'ulimit -n' | grep -q '^2051$'; then echo "RESULT: FAIL - nofile limit not applied"; exit 1; fi
[ "$(su - limituser3 -c 'ulimit -Sn')" = '2051' ] || { echo "RESULT: FAIL - soft nofile limit is wrong"; exit 1; }
[ "$(su - limituser3 -c 'ulimit -Hn')" = '2051' ] || { echo "RESULT: FAIL - hard nofile limit is wrong"; exit 1; }
echo "RESULT: PASS"
