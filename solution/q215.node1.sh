#!/usr/bin/env bash
set -euo pipefail
cat > /etc/nginx/sites-available/lfcs-proxy1 <<'EOF'
server { listen 18801; location / { proxy_pass http://192.168.56.12:18701; } }
EOF
ln -sf /etc/nginx/sites-available/lfcs-proxy1 /etc/nginx/sites-enabled/lfcs-proxy1
nginx -t
systemctl enable --now nginx
systemctl restart nginx
