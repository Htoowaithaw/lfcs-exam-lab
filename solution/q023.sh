#!/usr/bin/env bash
set -euo pipefail
cat >/usr/local/bin/q023-backup.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
tar -C /var/tmp/ec-q023/data -czf /root/q023-backup.tar.gz .
EOF
chmod 0755 /usr/local/bin/q023-backup.sh
