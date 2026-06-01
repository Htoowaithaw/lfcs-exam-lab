#!/usr/bin/env bash
set -euo pipefail
systemctl disable --now lfcs-q003.service >/dev/null 2>&1 || true
rm -f /run/lfcs-q003.ready /etc/systemd/system/lfcs-q003.service /usr/local/bin/lfcs-q003.sh
cat >/usr/local/bin/lfcs-q003.sh <<'EOF'
#!/usr/bin/env bash
echo ready > /run/lfcs-q003.ready
sleep infinity
EOF
chmod +x /usr/local/bin/lfcs-q003.sh
cat >/etc/systemd/system/lfcs-q003.service <<'EOF'
[Unit]
Description=LFCS Q003 broken service

[Service]
Type=simple
ExecStart=/usr/local/bin/lfcs-q003-missing.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
