#!/usr/bin/env bash
set -euo pipefail
useradd -m sudoer4
cat > /etc/sudoers.d/lfcs-sudo4 <<'EOF'
sudoer4 ALL=(root) NOPASSWD: /usr/bin/journalctl
EOF
chmod 0440 /etc/sudoers.d/lfcs-sudo4
visudo -cf /etc/sudoers.d/lfcs-sudo4
