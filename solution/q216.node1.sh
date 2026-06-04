#!/usr/bin/env bash
set -euo pipefail
cat > /etc/nginx/sites-available/lfcs-proxy2 <<'EOF'
server { listen 18802; location / { proxy_pass http://192.168.56.12:18702; } }
EOF
ln -sf /etc/nginx/sites-available/lfcs-proxy2 /etc/nginx/sites-enabled/lfcs-proxy2
nginx -t
systemctl enable --now nginx
systemctl restart nginx
