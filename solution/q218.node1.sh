#!/usr/bin/env bash
set -euo pipefail
cat > /etc/nginx/sites-available/lfcs-proxy4 <<'EOF'
server { listen 18804; location / { proxy_pass http://192.168.56.12:18704; } }
EOF
ln -sf /etc/nginx/sites-available/lfcs-proxy4 /etc/nginx/sites-enabled/lfcs-proxy4
nginx -t
systemctl enable --now nginx
systemctl restart nginx
