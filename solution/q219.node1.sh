#!/usr/bin/env bash
set -euo pipefail
cat > /etc/nginx/sites-available/lfcs-proxy5 <<'EOF'
server { listen 18805; location / { proxy_pass http://192.168.56.12:18705; } }
EOF
ln -sf /etc/nginx/sites-available/lfcs-proxy5 /etc/nginx/sites-enabled/lfcs-proxy5
nginx -t
systemctl enable --now nginx
systemctl restart nginx
