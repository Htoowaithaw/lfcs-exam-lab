#!/usr/bin/env bash
set -euo pipefail
cat > /etc/nginx/sites-available/lfcs-proxy3 <<'EOF'
server { listen 18803; location / { proxy_pass http://192.168.56.12:18703; } }
EOF
ln -sf /etc/nginx/sites-available/lfcs-proxy3 /etc/nginx/sites-enabled/lfcs-proxy3
nginx -t
systemctl enable --now nginx
systemctl restart nginx
