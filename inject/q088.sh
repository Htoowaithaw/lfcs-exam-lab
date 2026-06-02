#!/usr/bin/env bash
set -euo pipefail
cat > /usr/local/bin/lfcs-op-aa2 <<'EOF'
#!/usr/bin/env bash
cat /etc/hostname
EOF
chmod 0755 /usr/local/bin/lfcs-op-aa2
apparmor_parser -R /etc/apparmor.d/usr.local.bin.lfcs-op-aa2 >/dev/null 2>&1 || true
rm -f /etc/apparmor.d/usr.local.bin.lfcs-op-aa2
