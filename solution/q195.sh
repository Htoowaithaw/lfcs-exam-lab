#!/usr/bin/env bash
set -euo pipefail
useradd -m sudoer5
cat > /etc/sudoers.d/lfcs-sudo5 <<'EOF'
sudoer5 ALL=(root) NOPASSWD: /usr/bin/systemctl
EOF
chmod 0440 /etc/sudoers.d/lfcs-sudo5
visudo -cf /etc/sudoers.d/lfcs-sudo5
