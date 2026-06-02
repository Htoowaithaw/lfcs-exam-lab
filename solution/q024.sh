#!/usr/bin/env bash
set -euo pipefail
cat >/usr/local/bin/q024-count-fails.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
grep -c 'FAILED' /var/tmp/ec-q024/auth.log > /root/q024-fail-count.txt
EOF
chmod 0755 /usr/local/bin/q024-count-fails.sh
