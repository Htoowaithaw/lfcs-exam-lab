#!/usr/bin/env bash
set -euo pipefail
useradd -m sudoer1
cat > /etc/sudoers.d/lfcs-sudo1 <<'EOF'
sudoer1 ALL=(root) NOPASSWD: /usr/bin/systemctl
EOF
chmod 0440 /etc/sudoers.d/lfcs-sudo1
visudo -cf /etc/sudoers.d/lfcs-sudo1
