#!/usr/bin/env bash
set -euo pipefail
rm -f /usr/local/bin/q025-shell-report.sh /root/q025-bash-users.txt
rm -rf /var/tmp/ec-q025
mkdir -p /var/tmp/ec-q025
cat >/var/tmp/ec-q025/passwd.sample <<'EOF'
zara:x:1005:1005::/home/zara:/bin/bash
daemon:x:1:1::/usr/sbin:/usr/sbin/nologin
adam:x:1001:1001::/home/adam:/bin/bash
mona:x:1002:1002::/home/mona:/bin/sh
EOF
