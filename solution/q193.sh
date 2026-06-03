#!/usr/bin/env bash
set -euo pipefail
useradd -m sudoer3
cat > /etc/sudoers.d/lfcs-sudo3 <<'EOF'
sudoer3 ALL=(root) NOPASSWD: /usr/bin/systemctl
EOF
chmod 0440 /etc/sudoers.d/lfcs-sudo3
visudo -cf /etc/sudoers.d/lfcs-sudo3
