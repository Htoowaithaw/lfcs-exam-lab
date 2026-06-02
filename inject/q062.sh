#!/usr/bin/env bash
set -euo pipefail
cat > /usr/local/bin/lfcs-op-svc4.sh <<'EOF'
#!/usr/bin/env bash
mkdir -p /run
echo ready > /run/lfcs-op-svc4.ready
sleep infinity
EOF
chmod 0755 /usr/local/bin/lfcs-op-svc4.sh
cat > /etc/systemd/system/lfcs-op-svc4.service <<'EOF'
[Unit]
Description=Broken LFCS service q062
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/lfcs-op-svc4-wrong.sh
Restart=no

[Install]
WantedBy=multi-user.target
EOF
systemctl disable --now lfcs-op-svc4.service >/dev/null 2>&1 || true
systemctl daemon-reload
rm -f /run/lfcs-op-svc4.ready
