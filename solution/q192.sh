#!/usr/bin/env bash
set -euo pipefail
useradd -m sudoer2
cat > /etc/sudoers.d/lfcs-sudo2 <<'EOF'
sudoer2 ALL=(root) NOPASSWD: /usr/bin/journalctl
EOF
chmod 0440 /etc/sudoers.d/lfcs-sudo2
visudo -cf /etc/sudoers.d/lfcs-sudo2
