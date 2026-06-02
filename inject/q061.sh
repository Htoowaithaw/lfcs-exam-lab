#!/usr/bin/env bash
set -euo pipefail
cat > /usr/local/bin/lfcs-op-svc3.sh <<'EOF'
#!/usr/bin/env bash
mkdir -p /run
echo ready > /run/lfcs-op-svc3.ready
sleep infinity
EOF
chmod 0755 /usr/local/bin/lfcs-op-svc3.sh
cat > /etc/systemd/system/lfcs-op-svc3.service <<'EOF'
[Unit]
Description=Broken LFCS service q061
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/lfcs-op-svc3-wrong.sh
Restart=no

[Install]
WantedBy=multi-user.target
EOF
systemctl disable --now lfcs-op-svc3.service >/dev/null 2>&1 || true
systemctl daemon-reload
rm -f /run/lfcs-op-svc3.ready
