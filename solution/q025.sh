#!/usr/bin/env bash
set -euo pipefail
cat >/usr/local/bin/q025-shell-report.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
awk -F: '$7=="/bin/bash"{print $1}' /var/tmp/ec-q025/passwd.sample | sort > /root/q025-bash-users.txt
EOF
chmod 0755 /usr/local/bin/q025-shell-report.sh
